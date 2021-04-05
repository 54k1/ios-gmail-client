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
    convenience init(context: NSManagedObjectContext, label: GMailAPIService.Resource.Label) {
        self.init(context: context)
        self.id = label.id
        self.name = label.name
        self.color = label.color?.backgroundColor
        switch label.labelListVisibility ?? "show" {
        case "show":
            self.shouldHideLabel = false
        default:
            self.shouldHideLabel = true
        }
        if case .system = label.type {
            self.isSystemLabel = true
        } else {
            self.isSystemLabel = false
        }
    }

    static func fetch(id: String, in context: NSManagedObjectContext) -> Self? {
        return Self.findOrFetch(in: context, matching: NSPredicate(format: "id == %@", id))
    }
}

extension LabelMO {
    static var userLabelFetchRequest: NSFetchRequest<LabelMO> {
        let request = NSFetchRequest<LabelMO>(entityName: Self.entityName)
        request.predicate = NSPredicate(format: "isSystemLabel == false")
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(name), ascending: true)]
        return request
    }
}
