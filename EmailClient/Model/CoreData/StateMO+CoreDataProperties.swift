//
//  StateMO+CoreDataProperties.swift
//  EmailClient
//
//  Created by SV on 29/03/21.
//
//

import CoreData
import Foundation

public extension StateMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StateMO> {
        return NSFetchRequest<StateMO>(entityName: "State")
    }

    @NSManaged var latestHistoryId: String
    @NSManaged var id: String
}

extension StateMO: Identifiable {}
