//
//  CachedGMailAPIService.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import Foundation
import GoogleAPIClientForREST

class CachedGmailAPIService {
    let service: GMailAPIService
    let messageCache = NSCache<NSString, GMailAPIService.Resource.Message>()
    let threadsCache = NSCache<NSString, GMailAPIService.Resource.Thread>()
    let attachmentsCache = NSCache<NSString, Attachment>()
    let labelMetadataCache = NSCache<NSString, NSString>()
    var threadListForLabel = [String: [GMailAPIService.Resource.Thread]]()

    init(authorizationValue: String) {
        service = GMailAPIService(withAuthorizationValue: authorizationValue)
    }
}

// MARK: Fetch Threads

extension CachedGmailAPIService {
    typealias ThreadListResponseHandler = (GMailAPIService.Resource.ThreadListResponse?) -> Void

    func listThreads(withLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadListResponseHandler) {
        listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: nil, completionHandler: {
            threadListResponse in
            guard let threadListResponse = threadListResponse else {
                completionHandler(nil)
                return
            }
            if let latestThread = threadListResponse.threads?.first {
                // self.historyIdCache.setObject(latestThread.historyId as NSString, forKey: labelId as NSString)
            }

            completionHandler(threadListResponse)
        })
    }

    func listThreads(withLabelId labelId: String, withMaxResults maxResults: Int, withPageToken pageToken: String?, completionHandler: @escaping ThreadListResponseHandler) {
        let path: GMailAPIService.Method.Path = .threads(.list(userId: "me", pageToken: pageToken ?? ""))
        let queryParameters = [
            "labelIds": labelId,
            "maxResults": String(maxResults),
        ]
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
        if let thread = threadsCache.object(forKey: threadId as NSString) {
            completionHandler(thread)
            return
        }
        let path: GMailAPIService.Method.Path = .threads(.get(userId: "me", id: threadId))
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)
        service.executeMethod(method, completionHandler: {
            (thread: GMailAPIService.Resource.Thread?) in
            guard let thread = thread else {
                completionHandler(nil)
                return
            }
            // self.threadsCache.setObject(thread, forKey: threadId as NSString)
            completionHandler(thread)
        })
    }
}

extension CachedGmailAPIService {
    func get(messageWithId messageId: String, completionHandler: @escaping (GMailAPIService.Resource.Message?) -> Void) {
        let path: GMailAPIService.Method.Path = .messages(.get(id: messageId))
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil)

        service.executeMethod(method, completionHandler: {
            (message: GMailAPIService.Resource.Message?) in
            guard let message = message else {
                completionHandler(nil)
                return
            }
            completionHandler(message)
        })
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
    func listHistory(withStartHistoryId startHistoryId: String, withLabelId labelId: String, withHistoryType _: GMailAPIService.Resource.History.`Type`?, completionHandler: @escaping (GMailAPIService.Resource.History.ListResponse?) -> Void) {
        let path: GMailAPIService.Method.Path = .history(.list)
        let queryParameters: GMailAPIService.Method.QueryParameters = [
            "startHistoryId": startHistoryId,
            "labelId": labelId,
        ]

        let method = GMailAPIService.Method(pathParameters: path, queryParameters: queryParameters)
        service.executeMethod(method, completionHandler: {
            (response: GMailAPIService.Resource.History.ListResponse?) in
            if let latestHistoryId = response?.historyId {
                self.labelMetadataCache.setObject(latestHistoryId as NSString, forKey: labelId as NSString)
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

    func partialSync(forLabelId labelId: String, completionHandler _: @escaping ThreadListResponseHandler) {
        guard let startHistoryId = latestLocalHistoryId(forLabelId: labelId) else {
            NSLog("Latest historyId not fetched or was evicted")
            return
        }
        listHistory(withStartHistoryId: startHistoryId, withLabelId: labelId, withHistoryType: nil) {
            historyListResponse in
            guard let history = historyListResponse?.history, let latestHistoryId = historyListResponse?.historyId else {
                // Up to date
                return
            }

            self.labelMetadataCache.setObject(latestHistoryId as NSString, forKey: latestHistoryId as NSString)
            for history in history {
                if let messagesAdded = history.messagesAdded {
                    self.syncMessagesAdded(messagesAdded, forLabelId: labelId)
                }
            }
        }
    }

    private func syncMessagesAdded(_ messages: [GMailAPIService.Resource.History.MessageChanged], forLabelId labelId: String) {
        func syncMessage(_ message: GMailAPIService.Resource.History.Message) {
            guard let thread = threadsCache.object(forKey: message.threadId as NSString) else {
                // New thread, fetch it
                get(threadWithId: message.threadId, completionHandler: {
                    thread in
                    guard let thread = thread else {
                        return
                    }
                    self.threadListForLabel[labelId]?.append(thread)
                })
                return
            }
            get(messageWithId: message.id, completionHandler: {
                message in
                guard let message = message else {
                    return
                }
                thread.appendMessage(message)
            })
        }
        for message in messages {
            let message = message.message
            syncMessage(message)
        }
    }

    func fetchNextBatch(forLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping ThreadListResponseHandler) {
        listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: nil, completionHandler: {
            threadListResponse in
            guard let response = threadListResponse else {
                return
            }
            completionHandler(response)
        })
    }

    func fetchNextDetailBatch(forLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: @escaping (([GMailAPIService.Resource.Thread])?) -> Void) {
        listThreads(withLabelId: labelId, withMaxResults: maxResults, withPageToken: nil, completionHandler: {
            threadListResponse in
            guard let threads = threadListResponse?.threads else {
                return
            }
            var queries: [GTLRQuery] = []
            for thread in threads {
                let query = GTLRGmailQuery_UsersThreadsGet.query(withUserId: "me", identifier: thread.id)
                queries.append(query)
            }

            var threadDetails = [GMailAPIService.Resource.Thread]()
            let group = DispatchGroup()
            for thread in threads {
                group.enter()
                self.get(threadWithId: thread.id, completionHandler: {
                    thread in
                    defer {
                        group.leave()
                    }
                    guard let thread = thread else {
                        return
                    }
                    threadDetails.append(thread)
                })
            }
            // threadListResponse?.threads = threadDetails
            group.notify(qos: .background, flags: .noQoS, queue: .global(), execute: {
                completionHandler(threadDetails)
            })
        })
    }
}

// MARK: Local Sync

extension CachedGmailAPIService {
    /// List of threads cached locally in a database(ordered chronologically) whose size is less than or equal to maxResults
    func localThreadsSync(forLabelId _: String, maxResults _: Int, completionHandler: ThreadListResponseHandler) {
        // Indicate no local cache initially
        completionHandler(nil)
    }
}
