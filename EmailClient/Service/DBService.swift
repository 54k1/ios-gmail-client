//
//  DBService.swift
//  EmailClient
//
//  Created by SV on 26/03/21.
//

import CoreData
import Foundation

class DBService {
    private let context: NSManagedObjectContext
    private var fetchOffset = 0

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension DBService {
    func store(threads: [GMailAPIService.Resource.Thread]) {
        threads.forEach {
            thread in
            perform {
                _ = ThreadMO(context: self.context, thread: thread)
            }
        }
    }

    @discardableResult
    func store(thread: GMailAPIService.Resource.Thread) -> ThreadMO {
        return ThreadMO(context: context, thread: thread)
    }
}

extension DBService {
    func get(messageWithId messageId: String) -> MessageMO? {
        let request: NSFetchRequest<MessageMO> = MessageMO.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", messageId)
        request.predicate = predicate
        do {
            let messages = try context.fetch(request)
            if messages.count != 0 { return messages[0] }
            else { return nil }
        } catch let e {
            print(e)
            return nil
        }
    }

    func remove(messageWithId messageId: String) {
        guard let messageMO = get(messageWithId: messageId) else {
            return
        }
        perform {
            self.context.delete(messageMO)
        }
    }

    func disassociate(labelId: String, fromMessageWithId messageId: String) {
        guard let messageMO = get(messageWithId: messageId), let labelMO = get(labelWithId: labelId) else {
            NSLog("Unable to fetch messageMO or labelMO")
            return
        }
        perform {
            messageMO.removeFromLabels(labelMO)
        }
    }

    func associate(labelId: String, withMessageWithId messageId: String) {
        guard let messageMO = get(messageWithId: messageId), let labelMO = get(labelWithId: labelId) else {
            NSLog("Unable to fetch messageMO or labelMO")
            return
        }
        perform {
            messageMO.addToLabels(labelMO)
        }
    }
}

extension DBService {
    func get(labelWithId labelId: String) -> LabelMO? {
        let request: NSFetchRequest<LabelMO> = LabelMO.fetchRequest()
        let predicate = NSPredicate(format: "id like %@", labelId)
        request.predicate = predicate
        var ret: LabelMO? = nil
        context.performAndWait {
            do {
                let labels = try context.fetch(request)
                if labels.count != 0 {
                    ret = labels[0]
                }
            } catch let e {
                print(e)
            }
        }
        return ret
    }

    func store(label: GMailAPIService.Resource.Label) {
        perform {
            _ = LabelMO(context: self.context, label: label)
        }
    }}

extension DBService {
    func getState() -> StateMO? {
        let request: NSFetchRequest<StateMO> = StateMO.sortedFetchRequest
        do {
            let state = try context.fetch(request)
            if state.count != 0 {
                return state[0]
            } else {
                return nil
            }
        } catch let e {
            print(e)
            return nil
        }
    }

    func storeState(withHistoryId historyId: String) {
        perform {
            _ = StateMO(context: self.context, latestHistoryId: historyId)
        }
    }
}

extension DBService {
    func storeAttachment(withId attachmentId: String, withMessageId messageId: String, withFilename filename: String, location: String) {
        guard let messageMO = get(messageWithId: messageId) else {
            NSLog("Unable to fetch messageMO for attachment")
            return
        }
        
        perform {
            let attachmentMO = AttachmentMO(context: self.context)
        attachmentMO.id = attachmentId
        attachmentMO.message = messageMO
        attachmentMO.messageId = messageId
        attachmentMO.location = location
        attachmentMO.filename = filename
        }
    }

    func getAttachments(for threadId: String, callback: @escaping ([AttachmentMO]) -> Void) {
        let predicate = NSPredicate(format: "SUBQUERY(attachments, $a, ANY $a.message.thread.id LIKE %@).@count > 0", threadId)
        let request: NSFetchRequest<AttachmentMO> = AttachmentMO.fetchRequest()
        request.predicate = predicate
        
        perform {
            let attachments = try? self.context.fetch(request)
            if attachments == nil { callback([]) }
            else { callback(attachments!) }
        }
    }
}

extension DBService {
    func saveOrRollback() {
        perform {
            self._saveOrRollback()
        }
    }

    private func performAndSave(block: @escaping () -> Void) {
        context.perform {
            block()
            self._saveOrRollback()
        }
    }
    
    private func _saveOrRollback() {
        do {
            try self.context.save()
        } catch let err {
            print("SaveError: ", err)
            self.context.rollback()
        }
    }
    
    private func perform(block: @escaping () -> Void) {
        context.perform {
            block()
        }
    }
}
