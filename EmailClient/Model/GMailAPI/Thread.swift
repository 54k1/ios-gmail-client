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
    }

    class ThreadListResponse: Codable {
        var threads: [Thread]?
        let resultSizeEstimate: Int
        let nextPageToken: String?
    }
}
