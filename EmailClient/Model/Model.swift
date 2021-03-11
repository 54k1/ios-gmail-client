//
//  Model.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import Foundation
import GoogleAPIClientForREST

class History: Codable {
    let id: String
    struct Message: Codable {
        let id: String
        let threadId: String
        let labelIds: [String]?
    }

    struct MessageChanged: Codable {
        let message: Message
    }

    struct LabelsChanged: Codable {
        let message: Message
        let labelIds: [String]
    }

    let messagesAdded: [MessageChanged]?
    let messagesDeleted: [MessageChanged]?
    let labelsAdded: [LabelsChanged]?
    let labelsDeleted: [LabelsChanged]?
}

class HistoryListResponse: Codable {
    let historyId: String
    let nextPageToken: String?
    let history: [History]?
}

struct MessageList: Codable {
    struct PartMessage: Codable {
        let id: String
        let threadId: String
    }

    let messages: [PartMessage]
    let resultSizeEstimate: Int
    let nextPageToken: String?
}

class ThreadListResponse: Codable {
    struct PartThread: Codable {
        let id: String
        var snippet: String
        let historyId: String
    }

    var threads: [PartThread]?
    let resultSizeEstimate: Int
    let nextPageToken: String?
}

class ThreadDetail: Codable {
    var id: String
    var historyId: String
    var messages: [UserMessage]

    // For syncing
    func appendMessage(_ message: UserMessage) {
        messages.append(message)
        // As a result historyId is set to historyId of the message
        historyId = message.historyId
    }

    func deleteMessage(withId id: String) {
        messages.removeAll(where: { $0.id == id })
    }
}

class Model {
    static let shared = Model()
    static var token: String!
    enum HistoryId {
        case notFetched
        case fetched(String)
    }

    enum PageToken {
        case notFetched
        case fetched(token: String)
        case exhausted

        func toString() -> String {
            switch self {
            case .notFetched, .exhausted:
                return ""
            case let .fetched(token):
                return token
            }
        }
    }

    class Context {
        var labelIds = [String]()
        var nextPageToken: PageToken = .notFetched
        var latestHistoryId: HistoryId = .notFetched
        var threads = [ThreadListResponse.PartThread]()

        init(labelIds: [String], nextPageToken: PageToken, latestHistoryId: HistoryId, threads: [ThreadListResponse.PartThread]) {
            self.labelIds = labelIds
            self.nextPageToken = nextPageToken
            self.latestHistoryId = latestHistoryId
            self.threads = threads
        }
    }

    var contextFor = [UUID: Context]()
    func registerContext(withLabelIds labelIds: [String]) -> UUID {
        let uuid = UUID()
        contextFor[uuid] = Context(labelIds: labelIds, nextPageToken: .notFetched, latestHistoryId: .notFetched, threads: [ThreadListResponse.PartThread]())
        return uuid
    }

    func changeContext(toUUID id: UUID) {
        context = contextFor[id]!
    }

    var context: Context!

    var nextPageToken: PageToken {
        get {
            context.nextPageToken
        }
        set {
            context.nextPageToken = newValue
        }
    }

    var latestHistoryId: HistoryId {
        get {
            context.latestHistoryId
        }
        set {
            context.latestHistoryId = newValue
        }
    }

    var threads: [ThreadListResponse.PartThread] {
        get {
            context.threads
        }
        set {
            context.threads = newValue
        }
    }

    private init() {}

    var messageWithId = [String: UserMessage]()
    var threadDetailWithId = [String: ThreadDetail]()

    func makeRequest(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(Model.token!)", forHTTPHeaderField: "Authorization")
        return request
    }

    func fetchThread(withId threadId: String, _ completionHandler: @escaping (ThreadDetail) -> Void) {
        if let detail = threadDetailWithId[threadId] {
            completionHandler(detail)
        } else {
            let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads/\(threadId)")!
            Networker.request(makeRequest(url), completionHandler: {
                result in
                guard case let .success(data) = result else {
                    return
                }
                let decoder = JSONDecoder()
                guard let json = try? decoder.decode(ThreadDetail.self, from: data!) else {
                    return
                }
                self.threadDetailWithId[threadId] = json
                completionHandler(json)
            })
        }
    }

    let serviceEndpoint = "https://gmail.googleapis.com/gmail/v1"
    static let authorizationField = "Authorization"
    static var authorizationValue: String {
        "Bearer \(Model.token!)"
    }

    func fetchMessage(withId id: String, completionHandler: @escaping (UserMessage) -> Void) {
        if let message = messageWithId[id] {
            completionHandler(message)
        } else {
            let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)")!
            let request = makeRequest(url)
            Networker.request(request) {
                result in
                guard case let .success(data) = result else {
                    return
                }
                let decoder = JSONDecoder()
                guard let json = try? decoder.decode(UserMessage.self, from: data!) else {
                    return
                }
                completionHandler(json)
            }
        }
    }

    enum PartialSyncType: String {
        case messageAdded = "MESSAGE_ADDED"
        case messageDeleted = "MESSAGE_DELETED"
        // TODO: Labels
    }
}

extension Model {
    func fetchThreadDetail(withId threadId: String, completionHandler: @escaping (ThreadDetail) -> Void) {
        // Just fetch from network now
        if let threadDetail = threadDetailWithId[threadId] {
            completionHandler(threadDetail)
            return
        }
        let request = makeRequest(withMethod: .threads(.get(id: threadId)))
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<ThreadDetail>) in
            guard case let .success(threadDetail) = result else {
                return
            }
            self.localSync(threadDetail)
            completionHandler(threadDetail)
        }
    }
}

extension Model {
    class func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(Self.authorizationValue, forHTTPHeaderField: Self.authorizationField)
        return request
    }

    enum Method {
        enum MessageMethod {
            case get(id: String, attachmentId: String? = nil)
            case list
            case attachments(AttachmentMethod)
            
            enum AttachmentMethod {
                case get(id: String)
            }
        }

        case messages(MessageMethod)
        enum ThreadMethod {
            case list
            case get(id: String)
        }

        case threads(ThreadMethod)
        enum HistoryMethod {
            case list
        }

        case history(HistoryMethod)

        enum LabelMethod {
            case list
        }

        case labels(LabelMethod)

        func toString() -> String {
            var path = ""
            switch self {
            case let .messages(method):
                path += "/messages"
                switch method {
                case .list:
                    path += ""
                case .get(let id, let aid):
                    path += "/\(id)"
                    if let attachmentId = aid {
                        path += "/attachments/\(attachmentId)"
                    }
                case.attachments(let method):
                    path += "/attachments"
                    switch method {
                    case .get(let id):
                        path += "/get/\(id)"
                    }
                }
            case let .threads(method):
                path += "/threads"
                switch method {
                case let .get(id):
                    path += "/\(id)"
                case .list:
                    path += ""
                }
            case let .history(method):
                path += "/history"
                switch method {
                case .list:
                    path += ""
                }
            case let .labels(method):
                path += "/labels"
                switch method {
                case .list:
                    path += ""
                }
            }

            return path
        }
    }

    func makeRequest(withMethod method: Method, withQueryItems queryItems: [URLQueryItem]? = nil) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "gmail.googleapis.com"
        urlComponents.path = "/gmail/v1/users/me\(method.toString())"

        urlComponents.queryItems = queryItems

        let request = Self.makeRequest(url: urlComponents.url!)
        return request
    }
}

extension Model {
    func fetchNextThreadBatch(withSize size: Int, withLabelId labelId: String, completionHandler: @escaping (ThreadListResponse) -> Void) {
        if case .exhausted = nextPageToken {
            // No more threads to load
            return
        }

        let request = makeRequest(withMethod: .threads(.list), withQueryItems: [
            URLQueryItem(name: "labelIds", value: labelId),
            URLQueryItem(name: "maxResults", value: String(size)),
            URLQueryItem(name: "pageToken", value: nextPageToken.toString()),
        ])

        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<ThreadListResponse>) in
            guard case let .success(threadListResponse) = result else {
                return
            }
            if let pageToken = threadListResponse.nextPageToken {
                self.nextPageToken = .fetched(token: pageToken)
            } else {
                self.nextPageToken = .exhausted
            }
            if case .notFetched = self.latestHistoryId {
                if let threads = threadListResponse.threads {
                    self.latestHistoryId = .fetched(threads.first!.historyId)
                } else {}
            }
            if let threads = threadListResponse.threads {
                self.threads.append(contentsOf: threads)
            }
            completionHandler(threadListResponse)
        }
    }
}

extension Model {
    func localSync(_ threadDetail: ThreadDetail) {
        threadDetailWithId[threadDetail.id] = threadDetail
        for message in threadDetail.messages {
            messageWithId[message.id] = message
        }
    }

    // Call intially
    func fullSync(batchSize size: Int, withLabelId labelId: String, completionHandler: @escaping (ThreadListResponse) -> Void) {
        nextPageToken = .notFetched
        fetchNextThreadBatch(withSize: size, withLabelId: labelId, completionHandler: {
            threadListResponse in
            if let threads = threadListResponse.threads {
                if let historyId = threads.first?.historyId {
                    self.latestHistoryId = .fetched(historyId)
                }
            }
            // self.threads.append(contentsOf: threadListResponse.threads)
            completionHandler(threadListResponse)
        })
    }

    func partialSync(withLabelId labelId: String, completionHandler: @escaping () -> Void) {
        guard case let .fetched(historyId) = latestHistoryId else {
            NSLog("partialSync called when historyId not set")
            return
        }
        let request = makeRequest(withMethod: .history(.list), withQueryItems: [
            URLQueryItem(name: "startHistoryId", value: historyId),
            URLQueryItem(name: "labelId", value: labelId),
        ])
        print(request)
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<HistoryListResponse>) in
            guard case let .success(historyList) = result else {
                return
            }
            guard let history = historyList.history else {
                return
            }
            self.latestHistoryId = .fetched(historyList.historyId)
            for historyObject in history {
                let queue = DispatchQueue.global()
                let group = DispatchGroup()
                if let messagesAdded = historyObject.messagesAdded {
                    for addedMessage in messagesAdded {
                        group.enter()
                        self.fetchMessage(withId: addedMessage.message.id, completionHandler: {
                            newMessage in
                            self.messageWithId[newMessage.id] = newMessage
                            if let threadDetail = self.threadDetailWithId[newMessage.threadId] {
                                threadDetail.appendMessage(newMessage)
                                if let index = self.threads.firstIndex(where: { $0.id == threadDetail.id }) {
                                    self.threads[index] = ThreadListResponse.PartThread(id: threadDetail.id, snippet: newMessage.snippet, historyId: newMessage.id)
                                }
                            } else {
                                let partThread = ThreadListResponse.PartThread(id: newMessage.threadId, snippet: newMessage.snippet, historyId: newMessage.historyId)
                                self.threads.insert(partThread, at: 0)
                                group.enter()
                                queue.async(group: group) {
                                    self.fetchThreadDetail(withId: newMessage.threadId, completionHandler: { _ in
                                        group.leave()
                                    })
                                }
                            }
                            group.leave()
                        })
                    }
                }
                if let messagesDeleted = historyObject.messagesDeleted {
                    for deletedMessage in messagesDeleted {
                        let threadId = deletedMessage.message.threadId
                        let messageId = deletedMessage.message.id
                        // self.threadDetailWithId[threadId] = nil
                        self.messageWithId[messageId] = nil
                        self.threadDetailWithId[threadId]?.deleteMessage(withId: deletedMessage.message.id)
                        if self.threadDetailWithId[threadId]?.messages.isEmpty ?? false {
                            self.threadDetailWithId[threadId] = nil
                            self.threads.remove(at: self.threads.firstIndex(where: { $0.id == threadId })!)
                        }
                    }
                } else {
                    print("no deleted messages")
                }
                group.notify(queue: queue) {
                    self.threads.sort(by: {
                        let threadDetail0 = self.threadDetailWithId[$0.id]!
                        let threadDetail1 = self.threadDetailWithId[$1.id]!
                        return Int(threadDetail0.historyId)! > Int(threadDetail1.historyId)!
                    })
                    print("sorted")
                    completionHandler()
                }
            }
        }
    }
}

extension Model {
    struct Label: Codable {
        enum LabelType: String, Codable {
            case system
            case user
        }

        let id: String
        let name: String
        let messageListVisibility: String?
        let labelListVisibility: String?
        let type: LabelType
    }

    struct LabelsListResponse: Codable {
        let labels: [Label]
    }

    func fetchLabels(_ completionHandler: @escaping (LabelsListResponse) -> Void) {
        let request = makeRequest(withMethod: .labels(.list), withQueryItems: nil)
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<LabelsListResponse>) in
            guard case let .success(labelsListResponse) = result else {
                return
            }
            completionHandler(labelsListResponse)
            // for label in labelsListResponse.labels {
            //     print(label)
            // }
        }
    }
}

// MARK: Attachment

extension Model {
    func fetchAttachment(withId id: String, withMessageId messageId: String, completionHandler: @escaping (UserMessagePartBody) -> Void ) {
        let request = makeRequest(withMethod: .messages(.get(id: messageId, attachmentId: id)))
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<UserMessagePartBody>) in
            guard case .success(let partBody) = result else {
                return
            }
            completionHandler(partBody)
        }
    }
}
