//
//  DBService.swift
//  EmailClient
//
//  Created by SV on 26/03/21.
//

import CoreData
import Foundation

class DBService {
    let context: NSManagedObjectContext
    var fetchOffset = 0

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension DBService {
    typealias ThreadsHandler = ([ThreadMO]?) -> Void
    func fetchNextBatch(withLabelId labelId: String, withMaxResults maxResults: Int, completionHandler: ThreadsHandler) {
        let request: NSFetchRequest<ThreadMO> = ThreadMO.fetchRequest()
        request.fetchBatchSize = maxResults
        request.fetchOffset = fetchOffset
        do {
            let threads = try context.fetch(request)
            fetchOffset += threads.count
            completionHandler(threads.filter {
                ($0.messages!).contains {
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
            do {
                try context.save()
            } catch let e {
                print(e)
            }
        }
    }

    @discardableResult
    func store(thread: GMailAPIService.Resource.Thread) -> ThreadMO? {
        let threadMO = ThreadMO(context: context)
        threadMO.configure(with: thread, context: context)
        do {
            try context.save()
            return threadMO
        } catch let e {
            print(e)
            return nil
        }
    }
}
