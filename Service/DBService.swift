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
        let request: NSFetchRequest<ThreadMO> = ThreadMO.fetchRequest()
        request.fetchBatchSize = maxResults
        // request.fetchOffset = fetchOffset
        request.sortDescriptors = [NSSortDescriptor(key: "lastMessageDate", ascending: false)]
        do {
            let threads = try context.fetch(request)
            fetchOffset += threads.count
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
            let thread = ThreadMO(context: context)
            thread.configure(with: $0, context: self.context)
        }
    }

    @discardableResult
    func store(thread: GMailAPIService.Resource.Thread) -> ThreadMO? {
        let threadMO = ThreadMO(context: context)
        threadMO.configure(with: thread, context: context)
        return threadMO
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
        let labelMO = LabelMO(context: context)
        labelMO.configure(with: label)
    }

    func save() {
        do {
            try context.save()
        } catch let e {
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
