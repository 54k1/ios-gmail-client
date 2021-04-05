//
//  Managed.swift
//  EmailClient
//
//  Created by SV on 31/03/21.
//

import CoreData
import Foundation

protocol Managed: class {
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension Managed where Self: NSManagedObject {
    static var entityName: String {
        entity().name!
    }

    static var defaultSortDescriptors: [NSSortDescriptor] { [] }

    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        request.sortDescriptors = Self.defaultSortDescriptors
        return request
    }
}

extension Managed where Self: NSManagedObject {
    static func findOrCreate(in context: NSManagedObjectContext, matching predicate: NSPredicate, configure: (Self) -> Void) -> Self? {
        guard let object = findOrFetch(in: context, matching: predicate) else {
            // create it
            let object = Self(context: context)
            configure(object)
            return object
        }
        return object
    }

    static func findOrFetch(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        guard let object = materializedObject(in: context, matching: predicate) else {
            return fetch(in: context, requestConfiguration: {
                request in
                request.fetchLimit = 1
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
            }).first
        }
        return object
    }

    static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            if let result = object as? Self, predicate.evaluate(with: result) {
                return result
            }
        }
        return nil
    }

    static func fetch(in context: NSManagedObjectContext, requestConfiguration: (NSFetchRequest<Self>) -> Void = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        requestConfiguration(request)
        return try! context.fetch(request)
    }
}

public extension NSManagedObjectContext {
    func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch let err {
            print(err)
            rollback()
            return false
        }
    }
    
    func performChanges(block: @escaping () -> ()) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }
}
