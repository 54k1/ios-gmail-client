//
//  Label+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public extension LabelMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LabelMO> {
        return NSFetchRequest<LabelMO>(entityName: "Label")
    }

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var color: String?
    @NSManaged var nextPageToken: String?
    @NSManaged var shouldHideLabel: Bool
    @NSManaged var isSystemLabel: Bool
    @NSManaged var messages: NSSet
}

// MARK: Generated accessors for messages

public extension LabelMO {
    @objc(addMessagesObject:)
    @NSManaged func addToMessages(_ value: MessageMO)

    @objc(removeMessagesObject:)
    @NSManaged func removeFromMessages(_ value: MessageMO)

    @objc(addMessages:)
    @NSManaged func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged func removeFromMessages(_ values: NSSet)
}

extension LabelMO: Identifiable {}
