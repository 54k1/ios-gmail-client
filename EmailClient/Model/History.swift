//
//  History.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import Foundation

extension GMailAPIService.Resource {
    class History: Codable {
        let id: String
        let messages: [Message]?
        let messagesAdded: [MessageChanged]?
        let messagesDeleted: [MessageChanged]?
        let labelsAdded: [LabelChanged]?
        let labelsDeleted: [LabelChanged]?
    }
}

extension GMailAPIService.Resource.History {
    enum `Type`: String, Codable {
        case messageAdded = "MESSAGE_ADDED"
        case messageDeleted = "MESSAGE_DELETED"
        case labelAdded = "LABEL_ADDED"
        case labelRemoved = "LABEL_REMOVED"
    }

    struct Message: Codable {
        let id: String
        let threadId: String
        let labelIds: [String]?
    }

    struct MessageChanged: Codable {
        let message: Message
    }

    struct LabelChanged: Codable {
        let message: Message
        let labelIds: [String]
    }

    class ListResponse: Codable {
        let historyId: String
        let nextPageToken: String?
        let history: [GMailAPIService.Resource.History]?
    }
}
