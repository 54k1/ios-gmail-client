//
//  MessageComponentExtractor.swift
//  EmailClient
//
//  Created by SV on 25/02/21.
//

import Foundation
import GoogleAPIClientForREST

class MessageComponentExtractor {
    enum ExtractionError: String, Error {
        case payloadNotPresent
        case bodyNotPresent
        case badBody
        case unexpectedComponent
    }

    struct Attachment {
        let id: String
        var filename: String
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
}

extension MessageComponentExtractor {
    typealias Handler = (String, [Attachment]?) -> Void
    func extract(from message: GMailAPIService.Resource.Message, completionHandler: Handler) {
        guard case let .success(component) = extract(message.payload!) else {
            // TODO: Render error popup
            print("failure")
            return
        }

        var attachments: [Attachment]?
        var alternative: Alternative!
        var htmlContent: Content!
        if let mixed = component as? Mixed {
            alternative = mixed.alternative
            if !mixed.attachments.isEmpty {
                attachments = mixed.attachments
            }
        } else if let alt = component as? Alternative {
            alternative = alt
        } else if let content = component as? Content {
            htmlContent = content
        } else {
            NSLog("Cant interpret mime")
            return
        }

        if htmlContent == nil {
            guard let content = alternative.contents.first(where: {
                content in
                content.mimeType == "text/html"
            }) else {
                // Expect htmlContent to be present
                print("no html")
                return
            }
            htmlContent = content
        }

        let htmlString = "<html><head><meta charset='utf8'><meta name = 'viewport' content = 'width=device-width'></head>" + htmlContent.data + "</html>"

        completionHandler(htmlString, attachments)
    }

    private func extract(_ part: GMailAPIService.Resource.Message.Part) -> Result<Any, ExtractionError> {
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
}
