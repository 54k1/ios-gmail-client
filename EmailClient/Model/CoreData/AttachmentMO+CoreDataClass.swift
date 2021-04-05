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
    convenience init(context: NSManagedObjectContext, metaData: MessageComponentExtractor.AttachmentMetaData) {
        self.init(context: context)

        data = nil
        location = nil
        id = metaData.id
        filename = metaData.filename
        messageId = metaData.messageId
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
