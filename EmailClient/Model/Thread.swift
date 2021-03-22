//
//  Thread.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import Foundation

extension GMailAPIService.Resource {
    class Thread: Codable {
        var id: String
        var historyId: String
        var snippet: String?
        var messages: [Message]?

        // For syncing
        func appendMessage(_ message: Message) {
            messages?.append(message)
            // As a result historyId is set to historyId of the message
            historyId = message.historyId
        }

        func deleteMessage(withId id: String) {
            messages?.removeAll(where: { $0.id == id })
        }
    }

    class ThreadListResponse: Codable {
        // struct PartThread: Codable {
        //     let id: String
        //     var snippet: String
        //     let historyId: String
        // }

        var threads: [Thread]?
        let resultSizeEstimate: Int
        let nextPageToken: String?
    }
}

extension GMailAPIService.Resource.Thread {
    func list(forUserId _: String, completionHandler _: (GMailAPIService.Resource.Thread) -> Void) {}
}
