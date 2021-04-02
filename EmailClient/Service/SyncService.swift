//
//  CachedGMailAPIService.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import CoreData
import Foundation
import QuickLook

final class SyncService {
    private let service: GMailAPIService
    private let threadService: ThreadService
    private let messageService: MessageService
    private let attachmentService: AttachmentService
    private let dbService: DBService
    var latestHistoryId: String?
    let context: NSManagedObjectContext
    private let requestSerialQueue = DispatchQueue(label: "request.queue")

    init(authorizationValue: String, context: NSManagedObjectContext) {
        self.context = context
        service = GMailAPIService(withAuthorizationValue: authorizationValue)
        dbService = DBService(context: context)
        threadService = ThreadService(service: service)
        messageService = MessageService(service: service)
        attachmentService = AttachmentService(service: service)

        requestSerialQueue.async {
            self.shouldPerformFullSync(then: {
                self.requestSerialQueue.async {
                    self.fullSync(withMaxResults: 20)
                }
            })
        }
    }
}

// MARK: Readable typealiases

extension SyncService {
    private typealias Thread = GMailAPIService.Resource.Thread

    typealias OptionalHandler<T> = (T?) -> Void
    typealias ThreadListResponseHandler = OptionalHandler<GMailAPIService.Resource.ThreadListResponse>

    enum APIError: Error {
        case fullSyncNotPerformed
        case unableToPartialSync
    }

    typealias APIResult<T> = Result<T, APIError>
    typealias Handler<T> = (APIResult<T>) -> Void
}

// MARK: Fetch Labels

extension SyncService {
    func listLabels(completionHandler: @escaping (GMailAPIService.Resource.Label.ListResponse?) -> Void) {
        let path: GMailAPIService.Method.Path = .labels(.list)
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)

        service.executeMethod(method, completionHandler: {
            (labelListResponse: GMailAPIService.Resource.Label.ListResponse?) in
            completionHandler(labelListResponse)
        })
    }
}

// MARK: Fetch History

extension SyncService {
    private func listHistory(withStartHistoryId startHistoryId: String, withHistoryType _: GMailAPIService.Resource.History.`Type`?, completionHandler: @escaping (GMailAPIService.Resource.History.ListResponse?) -> Void) {
        let path: GMailAPIService.Method.Path = .history(.list)
        let queryParameters: GMailAPIService.Method.QueryParameters = [
            "startHistoryId": startHistoryId,
        ]

        let method = GMailAPIService.Method(pathParameters: path, queryParameters: queryParameters)
        service.executeMethod(method, completionHandler: {
            (response: GMailAPIService.Resource.History.ListResponse?) in
            if let latestHistoryId = response?.historyId {
                self.latestHistoryId = latestHistoryId
            }
            completionHandler(response)
        })
    }
}

// MARK: Partial Sync

extension SyncService {

    enum HistoryResponse {
        case upToDate
        case catchUp
    }

    func partialSync(completionHandler: @escaping Handler<HistoryResponse>) {
        guard let startHistoryId = latestHistoryId else {
            completionHandler(.failure(.fullSyncNotPerformed))
            NSLog("Latest historyId not fetched or was evicted")
            return
        }
        listHistory(withStartHistoryId: startHistoryId, withHistoryType: nil) {
            historyListResponseOptional in

            guard let historyListResponse = historyListResponseOptional else {
                completionHandler(.failure(.unableToPartialSync))
                return
            }

            guard let history = historyListResponse.history else {
                completionHandler(.success(.upToDate))
                return
            }

            self.dbService.storeState(withHistoryId: historyListResponse.historyId)

            let group = DispatchGroup()
            for history in history {
                if let messagesAdded = history.messagesAdded {
                    self.syncMessagesAdded(messagesAdded, group: group)
                }
                if let messagesDeleted = history.messagesDeleted {
                    self.syncMessagesDeleted(messagesDeleted)
                }
                if let labelsAdded = history.labelsAdded {
                    self.syncLabelsAdded(labelsAdded, group: group)
                }
                if let labelsDeleted = history.labelsRemoved {
                    self.syncLabelsDeleted(labelsDeleted)
                }
            }
            group.notify(queue: DispatchQueue.global()) {
                self.dbService.save()
                self.latestHistoryId = historyListResponse.historyId
                completionHandler(.success(.catchUp))
            }
        }
    }

    private func syncMessagesAdded(_ messages: [GMailAPIService.Resource.History.MessageChanged], group: DispatchGroup) {
        func syncMessage(_ message: GMailAPIService.Resource.History.Message) {
            group.enter()
            threadService.get(threadWithId: message.threadId, completionHandler: {
                threadOptional in
                defer {
                    group.leave()
                }
                guard let thread = threadOptional else { return }
                self.dbService.store(thread: thread)
            })
        }
        for message in messages {
            let message = message.message
            syncMessage(message)
        }
    }

    private func syncMessagesDeleted(_ messages: [GMailAPIService.Resource.History.MessageChanged]) {
        func syncMessage(_ message: GMailAPIService.Resource.History.Message) {
            let messageId = message.id
            dbService.remove(messageWithId: messageId)
        }
        for message in messages {
            let message = message.message
            syncMessage(message)
        }
    }

    private func syncLabelsAdded(_ labelsAdded: [GMailAPIService.Resource.History.LabelChanged], group _: DispatchGroup) {
        func syncLabel(_ labelAdded: GMailAPIService.Resource.History.LabelChanged) {
            let labelIds = labelAdded.labelIds
            let messageId = labelAdded.message.id
            labelIds.forEach {
                labelId in
                dbService.associate(labelId: labelId, withMessageWithId: messageId)
            }
        }

        for labelChange in labelsAdded {
            syncLabel(labelChange)
        }
    }

    private func syncLabelsDeleted(_ labelsDeleted: [GMailAPIService.Resource.History.LabelChanged]) {
        func syncLabel(_ labelAdded: GMailAPIService.Resource.History.LabelChanged) {
            let labelIds = labelAdded.labelIds
            let messageId = labelAdded.message.id
            labelIds.forEach {
                labelId in
                dbService.disassociate(labelId: labelId, fromMessageWithId: messageId)
            }
        }

        for labelChange in labelsDeleted {
            syncLabel(labelChange)
        }
    }
}

// MARK: Full Sync

extension SyncService {
    
    private func shouldPerformFullSync(then completionHandler: () -> Void) {
        if let state = dbService.getState() {
            latestHistoryId = state.latestHistoryId
        } else {
            completionHandler()
        }
    }

    private func fullSync(withMaxResults maxResults: Int) {
        let group = DispatchGroup()
        group.enter()
        fetchLabels {
            _ in
            group.enter()
            self.loadProfile {
                profile in
                guard let profile = profile else {
                    NSLog("Could not fetch profile")
                    return
                }
                self.latestHistoryId = profile.historyId
                group.enter()
                self.threadService.listDetail(forLabelId: nil, withMaxResults: maxResults, withPageToken: nil) {
                    threadList in
                    guard let threads = threadList?.threads else {
                        return
                    }
                    threads.forEach {
                        thread in
                        self.dbService.store(thread: thread)
                    }
                    group.leave()
                }
                self.dbService.storeState(withHistoryId: profile.historyId)
                group.leave()
            }
            group.leave()
        }
        group.notify(queue: DispatchQueue.global(), execute: {
            self.dbService.save()
            print("Hit save")
        })
    }
}

extension SyncService {
    private struct Profile: Codable {
        let emailAddress: String
        let messagesTotal: Int
        let threadsTotal: Int
        let historyId: String
    }

    private func loadProfile(completionHandler: @escaping OptionalHandler<Profile>) {
        let path: GMailAPIService.Method.Path = .users(.getProfile)
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)
        service.executeMethod(method, completionHandler: {
            (profile: Profile?) in
            completionHandler(profile)
        })
    }
}

extension SyncService {
    private func fetchLabels(completionHandler: @escaping ([String]) -> Void) {
        listLabels {
            labelListResponse in
            guard let labels = labelListResponse?.labels else {
                NSLog("Unable to list labels")
                return
            }
            var labelIds = [String]()
            labels.forEach {
                labelIds.append($0.id)
                self.dbService.store(label: $0)
            }
            completionHandler(labelIds)
        }
    }
}

// MARK: Attachments

extension SyncService {
    public func downloadAttachments(for threadId: String) {
        let group = DispatchGroup()
        dbService.getAttachments(for: threadId) {
            attachments in
            attachments.forEach {
                attachment in
                guard attachment.location == nil else {
                    // Already present
                    return
                }
                self.downloadAttachment(withId: attachment.id, withMessageId: attachment.messageId, completionHandler: {
                    url in
                    guard let url = url else { return }

                    attachment.location = url.absoluteString
                    self.generatePreviewThumbnail(forFileAt: url) {
                        image in
                        guard let image = image else { return }
                        attachment.thumbnail = image.pngData()
                    }
                })
            }
        }
    }

    private func downloadAttachment(withId attachmentId: String, withMessageId messageId: String, completionHandler: @escaping (URL?) -> Void) {
        attachmentService.fetchAttachmentContents(withId: attachmentId, withMessageId: messageId, completionHandler: {
            dataOptional in
            guard let data = dataOptional else {
                completionHandler(nil)
                return
            }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(attachmentId + messageId)
            do {
                try data.write(to: url)
                completionHandler(url)
            } catch {
                completionHandler(nil)
            }
        })
    }

    private func generatePreviewThumbnail(forFileAt url: URL, callback: @escaping (UIImage?) -> Void) {
        let size = CGSize(width: 300, height: 300)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 0.7, representationTypes: .all)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) {
            rep, err in
            guard err == nil, let rep = rep else {
                callback(nil)
                return
            }
            callback(rep.uiImage)
        }
    }
}
