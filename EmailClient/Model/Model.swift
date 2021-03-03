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

    var nextPageToken: PageToken = .notFetched
    var latestHistoryId: HistoryId = .notFetched

    private init() {}

    var messageWithId = [String: UserMessage]()
    var threadDetailWithId = [String: ThreadDetail]()
    var threads = [ThreadListResponse.PartThread]()

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
        let request = makeRequest(withMethod: .thread(.get(id: threadId)))
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
            case list
        }

        case message(MessageMethod)
        enum ThreadMethod {
            case list
            case get(id: String)
        }

        case thread(ThreadMethod)
        enum HistoryMethod {
            case list
        }

        case history(HistoryMethod)

        func toString() -> String {
            var path = ""
            switch self {
            case let .message(method):
                path += "/messages"
                switch method {
                case .list:
                    path += ""
                }
            case let .thread(method):
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
    func fetchNextThreadBatch(withSize size: Int, completionHandler: @escaping (ThreadListResponse) -> Void) {
        if case .exhausted = nextPageToken {
            // No more threads to load
            return
        }

        let request = makeRequest(withMethod: .thread(.list), withQueryItems: [
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
                self.latestHistoryId = .fetched(threadListResponse.threads.first!.historyId)
            }
            self.threads.append(contentsOf: threadListResponse.threads)
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
    func fullSync(batchSize size: Int, completionHandler: @escaping (ThreadListResponse) -> Void) {
        nextPageToken = .notFetched
        fetchNextThreadBatch(withSize: size, completionHandler: {
            threadListResponse in
            if let historyId = threadListResponse.threads.first?.historyId {
                self.latestHistoryId = .fetched(historyId)
            }
            // self.threads.append(contentsOf: threadListResponse.threads)
            completionHandler(threadListResponse)
        })
    }

    func partialSync(folder: FolderKind, completionHandler: @escaping () -> Void) {
        guard case let .fetched(historyId) = latestHistoryId else {
            NSLog("partialSync called when historyId not set")
            return
        }
        let request = makeRequest(withMethod: .history(.list), withQueryItems: [
            URLQueryItem(name: "startHistoryId", value: historyId),
            URLQueryItem(name: "labelId", value: folder.rawValue),
        ])
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
                        self.fetchMessage(withId: addedMessage.message.id, completionHandler: {
                            newMessage in
                            self.messageWithId[newMessage.id] = newMessage
                            if let threadDetail = self.threadDetailWithId[newMessage.threadId] {
                                threadDetail.appendMessage(newMessage)
                                if let index = self.threads.firstIndex(where: {$0.id == threadDetail.id}) {
                                    self.threads[index] = ThreadListResponse.PartThread(id: threadDetail.id, snippet: newMessage.snippet, historyId: newMessage.id)
                                }
                            } else {
                                let partThread = ThreadListResponse.PartThread(id: newMessage.threadId, snippet: newMessage.snippet, historyId: newMessage.historyId)
                                self.threads.insert(partThread, at: 0)
                                queue.async(group: group) {
                                    self.fetchThreadDetail(withId: newMessage.threadId, completionHandler: {_ in ()})
                                }
                            }
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
                    }
                }
                group.wait()
                self.threads.sort(by: {
                    let threadDetail0 = self.threadDetailWithId[$0.id]!
                    let threadDetail1 = self.threadDetailWithId[$1.id]!
                    return Int(threadDetail0.historyId)! > Int(threadDetail1.historyId)!
                })
                completionHandler()
            }
            
        }
    }
}
