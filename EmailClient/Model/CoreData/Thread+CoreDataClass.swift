//
//  Thread+CoreDataClass.swift
//
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

public class ThreadMO: NSManagedObject {}

extension ThreadMO {
    func configure(with thread: GMailAPIService.Resource.Thread, context: NSManagedObjectContext) {
        id = thread.id
        thread.messages?.forEach {
            let msg = MessageMO(context: context)
            msg.configure(with: $0, context: context)
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
