//
//  AttachmentMO+CoreDataClass.swift
//  EmailClient
//
//  Created by SV on 30/03/21.
//
//

import CoreData
import Foundation

public class AttachmentMO: NSManagedObject {}

extension AttachmentMO {
    func configure(with attachmentMetaData: MessageComponentExtractor.AttachmentMetaData, messageMO: MessageMO) {
        id = attachmentMetaData.id
        messageId = attachmentMetaData.messageId
        filename = attachmentMetaData.filename
        location = nil
        message = messageMO
        data = nil
    }
}

extension AttachmentMO {
    static func fetchRequest(for messageId: String) -> NSFetchRequest<AttachmentMO> {
        let request = NSFetchRequest<AttachmentMO>(entityName: "Attachment")
        request.predicate = NSPredicate(format: "messageId == %@", messageId)
        request.sortDescriptors = []
        return request
    }
}
