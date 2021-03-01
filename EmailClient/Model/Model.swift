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

class HistoryList: Codable {
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

    func fetchMessages(withThreadId threadId: String, _ completionHandler: @escaping ([UserMessage]) -> Void) {
        if let detail = threadDetailWithId[threadId] {
            completionHandler(detail.messages)
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
                completionHandler(json.messages)
            })
        }
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

    func fetchMessageList(withLabel label: String? = nil, withToken nextPageToken: String? = nil, maxResults: Int = 20, _ completionHandler: @escaping (MessageList) -> Void) {
        var queryItems = [URLQueryItem(name: "maxResults", value: maxResults.description)]
        if let label = label {
            queryItems.append(URLQueryItem(name: "labelIds", value: label))
        }
        if let nextPageToken = nextPageToken {
            queryItems.append(URLQueryItem(name: "nextPageToken", value: nextPageToken))
        }
        var component = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages")!
        component.queryItems = queryItems
        let url = component.url!
        print("url=", url)
        let request = makeRequest(url)
        Networker.request(request) {
            result in
            guard case let .success(data) = result else {
                return
            }
            let decoder = JSONDecoder()
            guard let json = try? decoder.decode(MessageList.self, from: data!) else {
                return
            }
            completionHandler(json)
        }
    }

    func fetchThreadList(withLabel label: String? = nil, withToken nextPageToken: String? = nil, maxResults: Int = 20, _ completionHandler: @escaping (ThreadListResponse) -> Void) {
        var queryItems = [URLQueryItem(name: "maxResults", value: maxResults.description)]
        if let label = label {
            queryItems.append(URLQueryItem(name: "labelIds", value: label))
        }
        if let nextPageToken = nextPageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: nextPageToken))
        }
        var component = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads")!
        component.queryItems = queryItems
        let url = component.url!
        print("url=", url)
        let request = makeRequest(url)
        Networker.request(request) {
            result in
            guard case let .success(data) = result else {
                return
            }
            let decoder = JSONDecoder()
            guard let json = try? decoder.decode(ThreadListResponse.self, from: data!) else {
                return
            }
            completionHandler(json)
        }
    }

    enum PartialSyncType: String {
        case messageAdded = "MESSAGE_ADDED"
        case messageDeleted = "MESSAGE_DELETED"
        // TODO: Labels
    }

    func partialSync(of folder: FolderKind? = nil, type: PartialSyncType = .messageAdded, completionHandler: @escaping ([MessageList.PartMessage]) -> Void) {
        if let historyId = latHistoryId {
            var url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/history?startHistoryId=\(historyId)?historyTypes=\(type)")!
            if let folder = folder {
                url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/history?startHistoryId=\(historyId)&labelId=\(folder.rawValue)")!
            }
            let request = makeRequest(url)
            Networker.request(request) {
                result in
                guard case let .success(data) = result else {
                    return
                }
                let decoder = JSONDecoder()
                var json: HistoryList?
                do {
                    json = try decoder.decode(HistoryList.self, from: data!)
                } catch let e {
                    print(e)
                    return
                }

                var updatedMessages = [MessageList.PartMessage]()
                if let history = json?.history {
                    for history in history {
                        if let messagesAdded = history.messagesAdded {
                            for message in messagesAdded {
                                let message = message.message
                                let part = MessageList.PartMessage(id: message.id, threadId: message.threadId)
                                updatedMessages.append(part)
                            }
                        }
                    }
                } else {
                    // Up to date
                }
                // update historyId
                self.latHistoryId = json?.historyId

                completionHandler(updatedMessages)
            }
        } else {
            fatalError("Perform full sync before partial sync")
        }
    }

    var latHistoryId: String!

    func fullSync(withLabel label: String? = nil, completionHandler: @escaping (ThreadListResponse) -> Void) {
        threadDetailWithId.removeAll()
        fetchThreadList(withLabel: label) {
            threadList in
            for thread in threadList.threads {
                self.fetchThread(withId: thread.id) { _ in () }
            }
            self.latHistoryId = threadList.threads[0].historyId
            completionHandler(threadList)
        }
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
            completionHandler(threadListResponse)
        })
    }

    func partialSync(folder: FolderKind) {
        guard case let .fetched(historyId) = latestHistoryId else {
            NSLog("partialSync called when historyId not set")
            return
        }
        let request = makeRequest(withMethod: .history(.list), withQueryItems: [
            URLQueryItem(name: "startHistoryId", value: historyId),
            URLQueryItem(name: "labelId", value: folder.rawValue),
        ])
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<HistoryList>) in
            guard case let .success(historyList) = result else {
                return
            }
            guard let history = historyList.history else {
                return
            }
            for historyObject in history {
                for addedMessage in historyObject.messagesAdded! {
                    self.fetchMessage(withId: addedMessage.message.id, completionHandler: {
                        message in
                        // self.threadDetailWithId[message.threadId].messages.append(message)
                        self.threadDetailWithId[message.threadId]?.messages.append(message)
                    })
                }
                for deletedMessage in historyObject.messagesDeleted! {
                    let threadId = deletedMessage.message.threadId
                    let messageId = deletedMessage.message.id
                    var messages = self.threadDetailWithId[threadId]!.messages
                    messages.remove(at: messages.firstIndex(where: { $0.id == messageId })!)
                    self.threadDetailWithId[threadId]?.messages = messages
                    // Update historyId of that thread
                }
            }
        }
    }
}
