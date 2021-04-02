//
//  Message+CoreDataClass.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

@objc(Message)
public class MessageMO: NSManagedObject {}

extension MessageMO {
    convenience init(context: NSManagedObjectContext, message: GMailAPIService.Resource.Message) {
        self.init(context: context)
        id = message.id
        snippet = message.snippet
        fromName = message.fromName
        fromEmail = message.fromEmail!
        subject = message.headerValueFor(key: "Subject") ?? "Subject"
        let extractor = MessageComponentExtractor()
        if case let .success(extracted) = extractor.extract(from: message) {
            html = extracted.html
            internalDate = extracted.date ?? Date()
            for attachment in extracted.attachments {
                let attachmentMO = AttachmentMO(context: context)
                attachmentMO.configure(with: attachment, messageMO: self)
                self.addToAttachments(attachmentMO)
            }
        } else {
            html = "<h1>Cannot render html</h1>"
            internalDate = Date()
        }

        message.labelIds.forEach {
            labelId in
            guard let label = LabelMO.fetch(id: labelId, in: context) else {
                NSLog("No lable with id: \(id)")
                return
            }
            self.addToLabels(label)
        }
    }
}
