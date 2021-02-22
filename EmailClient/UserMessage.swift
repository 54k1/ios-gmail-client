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

struct UserMessage: Codable {
    let id: String
    let threadId: String
    let labelIds: [String] // labels applied to the message
    let snippet: String // A 'short' part of the message
    let historyId: String
    let internalDate: String
    // Message body content parsed into payload
    let payload: UserMessagePart? // format=FULL
    let sizeEstimate: Int
    let raw: String? // filled only when format=RAW
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
struct UserMessagePart: Codable {
    let partId: String
    let mimeType: String
    let filename: String
    let headers: [UserHeader]
    let body: UserMessagePartBody?
    let parts: [UserMessagePart]?
}

struct UserHeader: Codable {
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
struct UserMessagePartBody: Codable {
    let attachmentId: String?
    let size: Int
    let data: String?
}
