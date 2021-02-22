//
//  Model.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import Foundation
import GoogleAPIClientForREST

class Model {
    static let shared = Model(dict: [String: UserMessage]())

    var messageWithId: [String: UserMessage]
    // threadId : [UserMessage]
    var messagesOfThread = [String: [UserMessage]]()
    var threadList: ThreadList?
    var threadListOfLabel = [String: ThreadList]()

    private init(dict: [String: UserMessage]) {
        messageWithId = dict
    }

    func getMessage(with id: String) -> UserMessage? {
        return messageWithId[id]
    }

    func fetchMessage(with id: String, _ completionHandler: @escaping (UserMessage?) -> Void) {
        if let message = messageWithId[id] {
            completionHandler(message)
        } else {
            let networker = Networker()
            let url = URL(string: "https://gmail.googleapis.com/users/me/messages/\(id)")!
            networker.fetch(fromURL: url) {
                (result: NetworkerResult<UserMessage>) in
                if case let .success(message) = result {
                    completionHandler(message)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }

    // func fetchAllMessages() {
    //     let networker = Networker()
    //     let url = URL(string: "https://gmail.googleapis.com/users/me/messages/")!
    //     networker.fetch(fromURL: url) {
    //         (result: NetworkerResult<[UserMessage]>) in {
    //
    //         }
    //     }
    // }

    func fetchMessages(withThreadId threadId: String, _ completionHandler: @escaping ([UserMessage]) -> Void) {
        print("fetch messages")
        if let messages = messagesOfThread[threadId] {
            completionHandler(messages)
        } else {
            let networker = Networker()
            let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads/\(threadId)")!
            print(url)
            networker.fetch(fromURL: url) {
                (result: NetworkerResult<ThreadDetail>) in
                debugPrint("successfully retreived messages")
                if case let .success(detail) = result {
                    self.messagesOfThread[threadId] = detail.messages
                    completionHandler(detail.messages)
                } else {}
            }
        }
    }

    let serviceEndpoint = "https://gmail.googleapis.com/gmail/v1"

    func fetchThreadList(withLabel label: String, _ completionHandler: @escaping (ThreadList) -> Void) {
        // if let threadList = threadListOfLabel[label] {
        //     completionHandler(threadList)
        // } else {
        // Fetch from network
        let networker = Networker()
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads?labelIds=\(label)")!
        networker.fetch(fromURL: url) {
            (result: NetworkerResult<ThreadList>) in
            guard case let .success(threadList) = result else {
                return
            }
            self.threadListOfLabel[label] = threadList
            completionHandler(threadList)
        }
        // }
    }

//    func fetchThread(with id: String, _ completionHandler: @escaping (ThreadList.PartThread?) -> ()) {
//        if let message = self.messageWithId[id] {
//            completionHandler(message)
//        } else {
//            let networker = Networker()
//            let url = URL(string: "https://gmail.googleapis.com/users/me/messages/\(id)")!
//            networker.fetch(fromURL: url) {
//                (result: NetworkerResult<ThreadList.PartThread>) in
//                if case .success(let message) = result {
//                    completionHandler(message)
//                } else {
//                completionHandler(nil)
//                }
//            }
//        }
//    }
}
