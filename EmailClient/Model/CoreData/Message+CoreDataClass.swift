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
    func configure(with message: GMailAPIService.Resource.Message, context: NSManagedObjectContext) {
        id = message.id
        snippet = message.snippet
        fromName = message.fromName
        fromEmail = message.fromEmail!
        subject = message.headerValueFor(key: "Subject") ?? "Subject"
        let extractor = MessageComponentExtractor()
        if case let .success(extracted) = extractor.extract(from: message) {
            html = extracted.html
            internalDate = extracted.date ?? Date()
        } else {
            html = "<h1>Cannot render html</h1>"
            internalDate = Date()
        }

        message.labelIds.forEach {
            labelId in
            let mo = LabelMO(context: context)
            mo.id = labelId
            mo.name = labelId
            self.addToLabels(mo)
        }
    }
}
