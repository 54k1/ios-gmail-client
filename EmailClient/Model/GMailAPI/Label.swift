//
//  Label.swift
//  EmailClient
//
//  Created by SV on 21/03/21.
//

import Foundation

extension GMailAPIService.Resource {
    class Label: Codable {
        let id: String
        let name: String
        let messageListVisibility: String?
        let labelListVisibility: String?
        let type: Type
        let messagesTotal: Int?
        let messagesUnread: Int?
        let threadsTotal: Int?
        let threadsUnread: Int?
        let color: Color?
    }
}

extension GMailAPIService.Resource.Label {
    enum `Type`: String, Codable {
        case system
        case user
    }

    class Color: Codable {
        let textColor: String
        let backgroundColor: String
    }

    class ListResponse: Codable {
        let labels: [GMailAPIService.Resource.Label]
    }

    /// For internal caching mechanism
    class MetaData {
        let historyId: String
        let nextPageToken: String

        init(historyId: String, nextPageToken: String) {
            self.historyId = historyId
            self.nextPageToken = nextPageToken
        }
    }
}
