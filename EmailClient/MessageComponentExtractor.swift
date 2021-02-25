//
//  MessageComponentExtractor.swift
//  EmailClient
//
//  Created by SV on 25/02/21.
//

import Foundation
import GoogleAPIClientForREST

enum ExtractionError: String, Error {
    case payloadNotPresent
    case bodyNotPresent
    case badBody
    case unexpectedComponent
}

struct Attachment {
    let id: String
    let filename: String
}

struct Alternative {
    let contents: [Content]
}

struct Mixed {
    let alternative: Alternative
    let attachments: [Attachment]
}

struct Content {
    let mimeType: String
    let data: String // Decoded data
}

// indirect enum MessageComponent {
//     case attachment(Attachment)
//     case alternative(parts: [MessageComponent])
//     case mixed(parts: [MessageComponent], alternative: MessageComponent, attachments: [MessageComponent])
//     case content(mimeType: String, data: String)
// }

func extract(_ part: UserMessagePart) -> Result<Any, ExtractionError> {
    switch part.mimeType {
    case "multipart/mixed":
        var alternative: Alternative?
        var attachments = [Attachment]()
        for part in part.parts! {
            let result = extract(part)
            guard case let .success(component) = result else {
                return result
            }

            if let alt = component as? Alternative {
                alternative = alt
            } else if let attachment = component as? Attachment {
                attachments.append(attachment)
            } else {
                return .failure(.unexpectedComponent)
            }
        }
        return .success(Mixed(alternative: alternative!, attachments: attachments))
    case "multipart/alternative":
        var contents = [Content]()
        for part in part.parts! {
            let result = extract(part)
            guard case let .success(component) = result else {
                return result
            }

            if let content = component as? Content {
                contents.append(content)
            } else {
                NSLog("Expected 'content' component & not \(component)")
                return .failure(.unexpectedComponent)
            }
        }
        return .success(Alternative(contents: contents))
    default:
        guard let body = part.body else {
            NSLog("Body not found in part")
            return .failure(.bodyNotPresent)
        }
        if let attachmentId = body.attachmentId {
            // Some attachment
            return .success(Attachment(id: attachmentId, filename: part.filename))
        } else if let data = body.data {
            let decodedData = GTLRDecodeWebSafeBase64(data)!
            let stringData = String(data: decodedData, encoding: .utf8)!
            return .success(Content(mimeType: part.mimeType, data: stringData))
        } else {
            // TODO:
            NSLog("")
            return .failure(.badBody)
        }
    }
}
