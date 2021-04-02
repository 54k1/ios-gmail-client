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
    typealias ThreadsHandler = ([ThreadMO]?) -> Void
    func fetchNextBatch(withLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: ThreadsHandler) {
        let request = ThreadMO.sortedFetchRequest
        request.fetchBatchSize = maxResults
        do {
            let threads = try context.fetch(request)
            completionHandler(threads.filter {
                $0.messages.contains {
                    messageMO in
                    (messageMO as! MessageMO).labels!.contains {
                        label in
                        (label as! LabelMO).id == labelId
                    }
                }
            })
        } catch let e {
            print(e)
            completionHandler(nil)
        }
    }

    func store(threads: [GMailAPIService.Resource.Thread]) {
        threads.forEach {
            _ = ThreadMO(context: context, thread: $0)
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
        context.delete(messageMO)
    }

    func disassociate(labelId: String, fromMessageWithId messageId: String) {
        guard let messageMO = get(messageWithId: messageId), let labelMO = get(labelWithId: labelId) else {
            NSLog("Unable to fetch messageMO or labelMO")
            return
        }
        messageMO.removeFromLabels(labelMO)
    }

    func associate(labelId: String, withMessageWithId messageId: String) {
        guard let messageMO = get(messageWithId: messageId), let labelMO = get(labelWithId: labelId) else {
            NSLog("Unable to fetch messageMO or labelMO")
            return
        }
        messageMO.addToLabels(labelMO)
    }
}

extension DBService {
    func get(labelWithId labelId: String) -> LabelMO? {
        let request: NSFetchRequest<LabelMO> = LabelMO.fetchRequest()
        let predicate = NSPredicate(format: "id like %@", labelId)
        request.predicate = predicate
        do {
            let labels = try context.fetch(request)
            if labels.count != 0 {
                return labels[0]
            } else {
                return nil
            }
        } catch let e {
            print(e)
            return nil
        }
    }

    func store(label: GMailAPIService.Resource.Label) {
        _ = LabelMO(context: context, id: label.id, name: label.name)
    }

    func save() {
        do {
            try context.save()
        } catch let e {
            context.rollback()
            print(e)
        }
    }
}

extension DBService {
    func getState() -> StateMO? {
        let request: NSFetchRequest<StateMO> = StateMO.fetchRequest()
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
        let stateMO = StateMO(context: context)
        stateMO.latestHistoryId = historyId
    }
}

extension DBService {
    func storeAttachment(withId attachmentId: String, withMessageId messageId: String, withFilename filename: String, location: String) {
        guard let messageMO = get(messageWithId: messageId) else {
            NSLog("Unable to fetch messageMO for attachment")
            return
        }
        let attachmentMO = AttachmentMO(context: context)
        attachmentMO.id = attachmentId
        attachmentMO.message = messageMO
        attachmentMO.messageId = messageId
        attachmentMO.location = location
        attachmentMO.filename = filename
        context.perform {
            do {
                try self.context.save()
            } catch let err {
                print(err)
            }
        }
    }

    func getAttachments(for threadId: String, callback: @escaping ([AttachmentMO]) -> Void) {
        let predicate = NSPredicate(format: "SUBQUERY(attachments, $a, ANY $a.message.thread.id LIKE %@).@count > 0", threadId)
        let request: NSFetchRequest<AttachmentMO> = AttachmentMO.fetchRequest()
        request.predicate = predicate
        performChanges(block: {
            let attachments = try? self.context.fetch(request)
            if attachments == nil { callback([]) }
            else { callback(attachments!) }
        })
    }
}

extension DBService {
    func saveOrRollback() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    func performChanges(block: @escaping () -> Void) {
        context.perform {
            block()
            _ = self.saveOrRollback()
        }
    }
}
