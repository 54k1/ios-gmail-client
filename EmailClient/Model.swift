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
        if let historyId = latestHistoryId {
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
                self.latestHistoryId = json?.historyId

                completionHandler(updatedMessages)
            }
        } else {
            fatalError("Perform full sync before partial sync")
        }
    }

    var latestHistoryId: String!

    func fullSync(withLabel label: String? = nil, completionHandler: @escaping (ThreadListResponse) -> Void) {
        threadDetailWithId.removeAll()
        fetchThreadList(withLabel: label) {
            threadList in
            for thread in threadList.threads {
                self.fetchThread(withId: thread.id) { _ in () }
            }
            self.latestHistoryId = threadList.threads[0].historyId
            completionHandler(threadList)
        }
    }
}

struct ModelConfiguration {
    let batchSize: Int
}

// Threads
extension Model {
    // func fetchThread() {
    //
    // }

    func fetchThreadList() {}
}

extension Model {
    func fetchThreadDetail(withId threadId: String, completionHandler: @escaping (ThreadDetail) -> Void) {
        // Just fetch from network now
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "gmail.googleapis.com"
        urlComponents.path = "/gmail/v1/users/me/threads/\(threadId)"

        let request = Self.makeRequest(url: urlComponents.url!)
        print("request=", request)
        Networker.fetch(fromRequest: request) {
            (result: NetworkerResult<ThreadDetail>) in
            guard case let .success(threadDetail) = result else {
                return
            }
            completionHandler(threadDetail)
        }
    }
}

extension Model {
    class func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(Self.authorizationValue, forHTTPHeaderField: Self.authorizationField)
        print("httpFields=", request.allHTTPHeaderFields)
        return request
    }
}
