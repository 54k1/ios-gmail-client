//
//  Thread+CoreDataClass.swift
//
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public final class ThreadMO: NSManagedObject {}

extension ThreadMO {
    convenience init(context: NSManagedObjectContext, thread: GMailAPIService.Resource.Thread) {
        self.init(context: context)
        id = thread.id
        thread.messages?.forEach {
            let msg = MessageMO(context: context, message: $0)
            addToMessages(msg)
        }

        if let dateString = thread.messages?[0].headerValueFor(key: "Date"), let date = Date(fromRFC822String: dateString) {
            lastMessageDate = date
        } else {
            lastMessageDate = Date()
        }
    }

    public var from: (name: String?, email: String) {
        (name: (messages[0] as? MessageMO)?.fromName, email: (messages[0] as! MessageMO).fromEmail)
    }
}

extension ThreadMO: Managed {
    static var defaultSortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(key: #keyPath(lastMessageDate), ascending: false)]
    }
}
