//
//  File.swift
//  EmailClient
//
//  Created by SV on 11/02/21.
//

import Foundation

/*
 {
   "id": string,
   "threadId": string,
   "labelIds": [
     string
   ],
   "snippet": string,
   "historyId": string,
   "internalDate": string,
   "payload": {
     object (MessagePart)
   },
   "sizeEstimate": integer,
   "raw": string
 }
 */

class UserMessage: Codable {
    var id: String
    var threadId: String
    var labelIds: [String] // labels applied to the message
    var snippet: String // A 'short' part of the message
    var historyId: String
    var internalDate: String
    // Message body content parsed into payload
    var payload: UserMessagePart? // format=FULL
    var sizeEstimate: Int
    var raw: String? // filled only when format=RAW
}

/*
 {
   "partId": string,
   "mimeType": string,
   "filename": string,
   "headers": [
     {
       object (Header)
     }
   ],
   "body": {
     object (MessagePartBody)
   },
   "parts": [
     {
       object (MessagePart)
     }
   ]
 }
 */
class UserMessagePart: Codable {
    var partId: String
    var mimeType: String
    var filename: String
    var headers: [UserHeader]
    var body: UserMessagePartBody?
    var parts: [UserMessagePart]?
}

class UserHeader: Codable {
    let name: String
    let value: String
}

/*
 {
   "attachmentId": string,
   "size": integer,
   "data": string
 }
 */
class UserMessagePartBody: Codable {
    let attachmentId: String?
    let size: Int
    let data: String?
}
