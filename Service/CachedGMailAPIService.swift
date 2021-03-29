//
//  CachedGMailAPIService.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import CoreData
import Foundation
import GoogleAPIClientForREST

class CachedGmailAPIService {
    let service: GMailAPIService
    let messageCache = NSCache<NSString, GMailAPIService.Resource.Message>()
    let threadsCache = NSCache<NSString, GMailAPIService.Resource.Thread>()
    let attachmentsCache = NSCache<NSString, Attachment>()
    let labelMetadataCache = NSCache<NSString, NSString>()
    var threadListForLabel = [String: [GMailAPIService.Resource.Thread]]()
    var latestHistoryId: String?
    let threadService: ThreadService
    let messageService: MessageService
    let dbService: DBService

    let requestSerialQueue = DispatchQueue(label: "request.queue")

    init(authorizationValue: String, context: NSManagedObjectContext) {
        service = GMailAPIService(withAuthorizationValue: authorizationValue)
        dbService = DBService(context: context)
        threadService = ThreadService(service: service)
        messageService = MessageService(service: service)

        requestSerialQueue.async {
            self.shouldPerformFullSync(then: {
                self.requestSerialQueue.async {
                    self.fullSync(withMaxResults: 20)
                }
            })
        }
    }
}

// MARK: Readable typealiases and Utility Methods

extension CachedGmailAPIService {
    private typealias Thread = GMailAPIService.Resource.Thread

    typealias OptionalHandler<T> = (T?) -> Void
    typealias ThreadListResponseHandler = OptionalHandler<GMailAPIService.Resource.ThreadListResponse>

    enum APIError: Error {
        case fullSyncNotPerformed
        case unableToPartialSync
    }

    typealias APIResult<T> = Result<T, APIError>
    typealias Handler<T> = (APIResult<T>) -> Void

    private func associate(thread: Thread, withLabelId labelId: String) {
        if threadListForLabel[labelId] == nil {
            threadListForLabel[labelId] = [Thread]()
        }
        threadListForLabel[labelId]?.append(thread)
    }

    private func disassociate(thread _: Thread, fromLabelId labelId: String) {
        guard threadListForLabel[labelId] != nil else { return }
        threadListForLabel[labelId]?.removeAll(where: {
            $0.messages?.contains(where: {
                $0.labelIds.contains(labelId)
            }) ?? false
        })
    }

    private func removeDuplicatesAndSortThreads() {
        threadListForLabel = threadListForLabel.mapValues {
            threads in
            threads.sorted(by: {
                $0.messages![0].internalDate > $1.messages![0].internalDate
                // $0.historyId > $1.historyId
            })
        }
    }
}

// MARK: Fetch Threads

extension CachedGmailAPIService {
    func listThreads(withLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadListResponseHandler) {
        listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: nil, completionHandler: {
            threadListResponse in
            guard let threadListResponse = threadListResponse else {
                completionHandler(nil)
                return
            }
            var latestHistory = ""
            threadListResponse.threads?.forEach {
                latestHistory = max(latestHistory, $0.historyId)
            }
            if let localLatestHistoryId = self.latestHistoryId {
                self.latestHistoryId = max(localLatestHistoryId, latestHistory)
            } else {
                self.latestHistoryId = latestHistory
            }
            self.labelMetadataCache.setObject(latestHistory as NSString, forKey: labelId as NSString)

            completionHandler(threadListResponse)
        })
    }

    func listThreads(withLabelId labelId: String?, withMaxResults maxResults: Int, withPageToken pageToken: String?, completionHandler: @escaping ThreadListResponseHandler) {
        let path: GMailAPIService.Method.Path = .threads(.list(userId: "me", pageToken: pageToken ?? ""))
        var queryParameters = [
            "maxResults": String(maxResults),
        ]
        if let labelId = labelId {
            queryParameters["labelIds"] = labelId
        }
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: queryParameters)
        service.executeMethod(method, completionHandler: {
            (threadList: GMailAPIService.Resource.ThreadListResponse?) in
            completionHandler(threadList)
        })
    }

    func getFromCache(threadWithId threadId: String) -> GMailAPIService.Resource.Thread? {
        threadsCache.object(forKey: threadId as NSString)
    }

    func get(threadWithId threadId: String, completionHandler: @escaping (GMailAPIService.Resource.Thread?) -> Void) {
        threadService.get(threadWithId: threadId) {
            threadOptional in
            guard let thread = threadOptional else {
                completionHandler(nil)
                return
            }
            completionHandler(thread)
        }
    }
}

extension CachedGmailAPIService {
    func get(messageWithId messageId: String, completionHandler: @escaping (GMailAPIService.Resource.Message?) -> Void) {
        messageService.get(messageWithId: messageId, completionHandler: completionHandler)
    }
}

// MARK: Fetch Attachements

extension CachedGmailAPIService {
    func getAttachment(withMetaData attachmentMetaData: MessageComponentExtractor.AttachmentMetaData, completionHandler: @escaping (Attachment?) -> Void) {
        let (messageId, attachmentId) = (attachmentMetaData.messageId, attachmentMetaData.id)
        let key = messageId + attachmentId as NSString

        let cachedItem = attachmentsCache.object(forKey: key)
        guard cachedItem == nil else {
            completionHandler(cachedItem)
            return
        }

        let path: GMailAPIService.Method.Path = .messages(.attachments(messageId: messageId, attachmentId: attachmentId))
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)
        service.executeMethod(method, completionHandler: {
            (body: GMailAPIService.Resource.Message.Part.Body?) in
            guard let body = body else {
                completionHandler(nil)
                return
            }
            let decoded = GTLRDecodeWebSafeBase64(body.data)
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(attachmentMetaData.filename)
            try? decoded!.write(to: path)
            let attachment = Attachment(withName: attachmentMetaData.filename, withURL: path)
            self.attachmentsCache.setObject(attachment, forKey: key)
            completionHandler(attachment)
        })
    }

    func get(_ attachments: [MessageComponentExtractor.AttachmentMetaData], forMessageId messageId: String, completionHandler: @escaping ([Attachment]?) -> Void) {
        var atts = [Attachment]()
        let queue = DispatchQueue(label: "\(messageId).attachments", attributes: .concurrent)
        let group = DispatchGroup()
        for attachment in attachments {
            let (messageId, id) = (messageId, attachment.id)
            let key = messageId + id as NSString
            if let attachmentURL = attachmentsCache.object(forKey: key) {
                queue.async(group: group, qos: .default, flags: .barrier) {
                    atts.append(attachmentURL)
                }
                continue
            }
            let path: GMailAPIService.Method.Path = .messages(.attachments(messageId: messageId, attachmentId: id))
            let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)
            group.enter()
            service.executeMethod(method, completionHandler: {
                (body: GMailAPIService.Resource.Message.Part.Body?) in
                guard let body = body else {
                    completionHandler(nil)
                    return
                }
                let decoded = GTLRDecodeWebSafeBase64(body.data)
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(attachment.filename)
                try? decoded!.write(to: path)
                let attachment = Attachment(withName: attachment.filename, withURL: path)
                self.attachmentsCache.setObject(attachment, forKey: key)
                queue.async(group: nil, qos: .default, flags: .barrier) {
                    atts.append(attachment)
                    group.leave()
                }
            })
        }
        DispatchQueue.global().async {
            group.wait()
            completionHandler(atts)
        }
    }
}

// MARK: Fetch Labels

extension CachedGmailAPIService {
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

extension CachedGmailAPIService {
    func listHistory(withStartHistoryId startHistoryId: String, withHistoryType _: GMailAPIService.Resource.History.`Type`?, completionHandler: @escaping (GMailAPIService.Resource.History.ListResponse?) -> Void) {
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

// MARK: Syncing

extension CachedGmailAPIService {
    func latestLocalHistoryId(forLabelId labelId: String) -> String? {
        return labelMetadataCache.object(forKey: labelId as NSString) as String?
    }

    enum HistoryResponse {
        case upToDate
        case catchUp([ViewModel.Thread])
    }

    func partialSync(andReturnThreadsWithLabelId _: String, completionHandler: @escaping Handler<HistoryResponse>) {
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
                print("history=", history)
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
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                self.dbService.save()
                self.latestHistoryId = historyListResponse.historyId
                completionHandler(.success(.catchUp([])))
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
            let (threadId, messageId) = (message.threadId, message.id)
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

    typealias ThreadVMsHandler = ([ViewModel.Thread]) -> Void
    func fetchNextBatch(forLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadVMsHandler) {
        dbService.fetchNextBatch(withLabelId: labelId, withMaxResults: maxResults) {
            threadMOs in
            guard let threadMOs = threadMOs else {
                return
            }
            let threadVMs = threadMOs.compactMap {
                threadMO in
                ViewModel.Thread(from: threadMO)
            }
            guard threadVMs.count == 0 else {
                completionHandler(threadVMs)
                return
            }
            listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: nil) {
                threadListResponse in
                var threadVMs = [ViewModel.Thread]()

                guard let threads = threadListResponse?.threads else {
                    completionHandler(threadVMs)
                    return
                }
                let group = DispatchGroup()
                threads.forEach {
                    group.enter()
                    self.get(threadWithId: $0.id, completionHandler: {
                        thread in
                        defer {
                            group.leave()
                        }
                        guard let thread = thread else {
                            return
                        }
                        guard let mo = self.dbService.store(thread: thread) else {
                            return
                        }
                        let vm = ViewModel.Thread(from: mo)
                        threadVMs.append(vm)
                    })
                }

                group.notify(queue: DispatchQueue.global()) {
                    completionHandler(threadVMs)
                }
            }
        }
    }

    func networkedFetchNextBatch(forLabelId labelId: String?, withMaxResults maxResults: Int, withPageToken pageToken: String?, completionHandler: @escaping ThreadListResponseHandler) {
        listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: pageToken) {
            threadListResponse in
            guard let threads = threadListResponse?.threads else {
                completionHandler(nil)
                return
            }
            let group = DispatchGroup()

            var threadWithId = [String: Thread]()
            threads.forEach {
                group.enter()
                self.get(threadWithId: $0.id, completionHandler: {
                    thread in
                    defer {
                        group.leave()
                    }
                    guard let thread = thread else {
                        return
                    }
                    threadWithId[thread.id] = thread
                })
            }

            group.notify(queue: DispatchQueue.global()) {
                threadListResponse?.threads = threadListResponse?.threads?.compactMap {
                    threadWithId[$0.id]
                }
                completionHandler(threadListResponse)
            }
        }
    }
}

// MARK: Local Sync

extension CachedGmailAPIService {
    /// List of threads cached locally in a database(ordered chronologically) whose size is less than or equal to maxResults
    func localThreadsSyncOrFullSync(forLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadVMsHandler) {
        requestSerialQueue.async {
            self.localSync(forLabelId: labelId, withMaxResults: maxResults, completionHandler: {
                threadVMs in
                guard threadVMs.count != 0 else {
                    self.fetchNextBatch(forLabelId: labelId, withMaxResults: maxResults) {
                        threadVMs in
                        completionHandler(threadVMs)
                    }
                    return
                }
                completionHandler(threadVMs)
            })
        }
    }

    private func localSync(forLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadVMsHandler) {
        dbService.fetchNextBatch(withLabelId: labelId, withMaxResults: maxResults) {
            threads in
            completionHandler(threads?.compactMap {
                ViewModel.Thread(from: $0)
            } ?? [])
        }
    }

    private func shouldPerformFullSync(then completionHandler: () -> Void) {
        if let state = dbService.getState() {
            latestHistoryId = state.latestHistoryId
        } else {
            completionHandler()
        }
    }

    /// Perform when db is empty
    // Fetch 20 (at the most) threads from each label and store them in the db
    // Also store the nextPageToken of each of them
    func fullSync(withMaxResults maxResults: Int) {
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
                self.networkedFetchNextBatch(forLabelId: nil, withMaxResults: maxResults, withPageToken: nil) {
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

extension CachedGmailAPIService {
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

extension CachedGmailAPIService {
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
