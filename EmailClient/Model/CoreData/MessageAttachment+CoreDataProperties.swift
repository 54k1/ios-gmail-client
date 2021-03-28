//
//  MessageAttachment+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public extension AttachmentMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AttachmentMO> {
        return NSFetchRequest<AttachmentMO>(entityName: "MessageAttachment")
    }

    @NSManaged var id: String?
    @NSManaged var location: String?
    @NSManaged var message: MessageMO?
}

extension AttachmentMO: Identifiable {}
