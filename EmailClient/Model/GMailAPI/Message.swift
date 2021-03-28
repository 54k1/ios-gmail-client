//
//  File.swift
//  EmailClient
//
//  Created by SV on 11/02/21.
//

import Foundation

extension GMailAPIService.Resource {
    class Message: Codable {
        var id: String
        var threadId: String
        var labelIds: [String]
        var snippet: String
        var historyId: String
        var internalDate: String
        var payload: Part?
        var sizeEstimate: Int
        var raw: String?
    }
}

extension GMailAPIService.Resource.Message {
    class Part: Codable {
        var partId: String
        var mimeType: String
        var filename: String
        var headers: [Header]
        var body: Body?
        var parts: [Part]?
    }
}

extension GMailAPIService.Resource.Message.Part {
    class Header: Codable {
        let name: String
        let value: String
    }

    class Body: Codable {
        let attachmentId: String?
        let size: Int
        let data: String?
    }
}
