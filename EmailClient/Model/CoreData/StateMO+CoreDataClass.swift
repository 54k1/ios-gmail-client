//
//  StateMO+CoreDataClass.swift
//  EmailClient
//
//  Created by SV on 29/03/21.
//
//

import CoreData
import Foundation

@objc(StateMO)
public class StateMO: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext, latestHistoryId: String) {
        self.init(context: context)
        self.latestHistoryId = latestHistoryId
        self.lastUpdated = Date()
    }
}

extension StateMO: Managed {
    static var defaultSortDescriptors: [NSSortDescriptor] = [
        .init(key: #keyPath(lastUpdated), ascending: false)
    ]
}
