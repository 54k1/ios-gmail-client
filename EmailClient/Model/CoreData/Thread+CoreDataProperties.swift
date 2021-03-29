//
//  Thread+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public extension ThreadMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ThreadMO> {
        return NSFetchRequest<ThreadMO>(entityName: "Thread")
    }

    @NSManaged var id: String?
    @NSManaged var lastMessageDate: Date
    @NSManaged var messages: NSOrderedSet
}

// MARK: Generated accessors for messages

public extension ThreadMO {
    @objc(insertObject:inMessagesAtIndex:)
    @NSManaged func insertIntoMessages(_ value: MessageMO, at idx: Int)

    @objc(removeObjectFromMessagesAtIndex:)
    @NSManaged func removeFromMessages(at idx: Int)

    @objc(insertMessages:atIndexes:)
    @NSManaged func insertIntoMessages(_ values: [MessageMO], at indexes: NSIndexSet)

    @objc(removeMessagesAtIndexes:)
    @NSManaged func removeFromMessages(at indexes: NSIndexSet)

    @objc(replaceObjectInMessagesAtIndex:withObject:)
    @NSManaged func replaceMessages(at idx: Int, with value: MessageMO)

    @objc(replaceMessagesAtIndexes:withMessages:)
    @NSManaged func replaceMessages(at indexes: NSIndexSet, with values: [MessageMO])

    @objc(addMessagesObject:)
    @NSManaged func addToMessages(_ value: MessageMO)

    @objc(removeMessagesObject:)
    @NSManaged func removeFromMessages(_ value: MessageMO)

    @objc(addMessages:)
    @NSManaged func addToMessages(_ values: NSOrderedSet)

    @objc(removeMessages:)
    @NSManaged func removeFromMessages(_ values: NSOrderedSet)
}
