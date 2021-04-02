//
//  Label+CoreDataClass.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

@objc(Label)
public class LabelMO: NSManagedObject {}

extension LabelMO: Managed {}

extension LabelMO {
    convenience init(context: NSManagedObjectContext, id: String, name: String) {
        self.init(context: context)
        self.id = id
        self.name = name
    }

    static func fetch(id: String, in context: NSManagedObjectContext) -> Self? {
        return Self.findOrFetch(in: context, matching: NSPredicate(format: "id == %@", id))
    }
}
