//
//  Message+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public extension MessageMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MessageMO> {
        return NSFetchRequest<MessageMO>(entityName: "Message")
    }

    @NSManaged var id: String
    @NSManaged var snippet: String
    @NSManaged var internalDate: Date
    @NSManaged var html: String
    @NSManaged var subject: String
    @NSManaged var fromName: String?
    @NSManaged var fromEmail: String
    @NSManaged var thread: ThreadMO?
    @NSManaged var labels: NSSet?
    @NSManaged var attachments: NSSet?
}

// MARK: Generated accessors for labels

public extension MessageMO {
    @objc(addLabelsObject:)
    @NSManaged func addToLabels(_ value: LabelMO)

    @objc(removeLabelsObject:)
    @NSManaged func removeFromLabels(_ value: LabelMO)

    @objc(addLabels:)
    @NSManaged func addToLabels(_ values: NSSet)

    @objc(removeLabels:)
    @NSManaged func removeFromLabels(_ values: NSSet)
}

// MARK: Generated accessors for attachments

public extension MessageMO {
    @objc(addAttachmentsObject:)
    @NSManaged func addToAttachments(_ value: AttachmentMO)

    @objc(removeAttachmentsObject:)
    @NSManaged func removeFromAttachments(_ value: AttachmentMO)

    @objc(addAttachments:)
    @NSManaged func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged func removeFromAttachments(_ values: NSSet)
}

extension MessageMO: Identifiable {}
