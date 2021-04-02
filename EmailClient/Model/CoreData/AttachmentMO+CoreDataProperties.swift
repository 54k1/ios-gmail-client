//
//  AttachmentMO+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 30/03/21.
//
//

import CoreData
import Foundation

public extension AttachmentMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AttachmentMO> {
        return NSFetchRequest<AttachmentMO>(entityName: "Attachment")
    }

    @NSManaged var id: String
    @NSManaged var data: Data?
    @NSManaged var filename: String
    @NSManaged var thumbnail: Data?
    @NSManaged var location: String?
    @NSManaged var messageId: String
    @NSManaged var message: MessageMO
}

extension AttachmentMO: Identifiable {}
