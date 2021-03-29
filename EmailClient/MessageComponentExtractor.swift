//
//  MessageComponentExtractor.swift
//  EmailClient
//
//  Created by SV on 25/02/21.
//

import Foundation
import GoogleAPIClientForREST

class MessageComponentExtractor {
    typealias MessageResult = Result<Message, ExtractionError>
    enum ExtractionError: String, Error {
        case payloadNotPresent
        case bodyNotPresent
        case badBody
        case unexpectedComponent
        case badMime
        case htmlNotPresent
    }

    struct AttachmentMetaData {
        let id: String
        let messageId: String
        var filename: String
    }

    struct Alternative {
        let contents: [Content]
    }

    struct Mixed {
        let alternative: Alternative
        let attachments: [AttachmentMetaData]
    }

    struct Content {
        let mimeType: String
        let data: String // Decoded data
    }

    struct Message {
        struct User {
            let name: String
            let email: String
        }

        let from: User?
        let to: User?
        let dateString: String?
        let date: Date?
        let html: String
        let attachments: [AttachmentMetaData]
    }
}

extension MessageComponentExtractor {
    func extract(from message: GMailAPIService.Resource.Message) -> Result<Message, ExtractionError> {
        guard let payload = message.payload, case let .success(component) = extract(payload, messageId: message.id) else {
            return .failure(.badBody)
        }

        var attachments = [AttachmentMetaData]()
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
            return .failure(.badMime)
        }

        if htmlContent == nil {
            guard let content = alternative.contents.first(where: {
                content in
                content.mimeType == "text/html"
            }) else {
                // Expect htmlContent to be present
                NSLog("HTML not present")
                return .failure(.htmlNotPresent)
            }
            htmlContent = content
        }

        let htmlString = "<html><head><meta charset='utf8'><meta name = 'viewport' content = 'width=device-width'></head>" + htmlContent.data + "</html>"

        var fromUser, toUser: Message.User?
        if let fromName = message.fromName, let fromEmail = message.fromEmail {
            fromUser = Message.User(name: fromName, email: fromEmail)
        }
        if let toName = message.toName, let toEmail = message.toEmail {
            toUser = Message.User(name: toName, email: toEmail)
        }

        return .success(Message(from: fromUser, to: toUser, dateString: message.dateString, date: message.date, html: htmlString, attachments: attachments))
    }

    private func extract(_ part: GMailAPIService.Resource.Message.Part, messageId: String) -> Result<Any, ExtractionError> {
        switch part.mimeType {
        case "multipart/mixed":
            var alternative: Alternative?
            var attachments = [AttachmentMetaData]()
            for part in part.parts! {
                let result = extract(part, messageId: messageId)
                guard case let .success(component) = result else {
                    return result
                }

                if let alt = component as? Alternative {
                    alternative = alt
                } else if let attachment = component as? AttachmentMetaData {
                    attachments.append(attachment)
                } else {
                    return .failure(.unexpectedComponent)
                }
            }
            return .success(Mixed(alternative: alternative!, attachments: attachments))
        case "multipart/alternative":
            var contents = [Content]()
            for part in part.parts! {
                let result = extract(part, messageId: messageId)
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
                return .success(AttachmentMetaData(id: attachmentId, messageId: messageId, filename: part.filename))
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

/// Extracting necessary information from Message
extension GMailAPIService.Resource.Message {
    func headerValueFor(key: String) -> String? {
        if let payload = self.payload {
            for header in payload.headers {
                if header.name == key {
                    return header.value
                }
            }
        }
        return nil
    }

    var fromName: String? {
        guard let from = headerValueFor(key: "From") else {
            return nil
        }
        return Self.extractName(from)
    }

    var fromEmail: String? {
        guard let from = headerValueFor(key: "From") else {
            return nil
        }
        return Self.extractEmail(from)
    }

    private static func extractName(_ string: String) -> String {
        if let index = string.firstIndex(of: "<") {
            return String(string.prefix(upTo: index))
        }
        return string
    }

    private static func extractEmail(_ string: String) -> String {
        if let index = string.firstIndex(of: "<") {
            return String(string.suffix(from: index))
        }
        return string
    }

    var toName: String? {
        guard let to = headerValueFor(key: "To") else {
            return nil
        }
        return Self.extractName(to)
    }

    var toEmail: String? {
        guard let to = headerValueFor(key: "To") else {
            return nil
        }
        return Self.extractEmail(to)
    }

    var dateString: String? {
        guard let dateString = headerValueFor(key: "Date"), let date = Date(fromRFC822String: dateString) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if date.distance(to: Date()) > 24 * 60 * 60 {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }

    var date: Date? {
        guard let dateString = headerValueFor(key: "Date") else {
            return nil
        }
        return Date(fromRFC822String: dateString)
    }
}

extension Date {
    init?(fromRFC822String dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        guard let date = formatter.date(from: dateString) else {
            return nil
        }
        self = date
    }
}
