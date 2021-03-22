//
//  ThreadsProvider.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation
import UIKit

class ThreadsLoader: NSObject {
    private var threads = [GMailAPIService.Resource.Thread]()
    private let service: CachedGmailAPIService
    private let labelId: String
    private let maxResults = 10
    
    init(forLabelId labelId: String, service: CachedGmailAPIService) {
        self.service = service
        self.labelId = labelId
    }
}

extension ThreadsLoader {
    func getThread(atIndexPath indexPath: IndexPath) -> GMailAPIService.Resource.Thread? {
        threads[indexPath.row]
    }
}

extension ThreadsLoader: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath) as? ThreadTableViewCell else {
            return UITableViewCell()
        }

        let row = indexPath.row
        let thread = threads[row]
        
        if let messages = thread.messages {
            cell.configure(with: thread)
            return cell
        }
        
        cell.startLoading()
        service.get(threadWithId: thread.id, completionHandler: {
            threadDetail in
            guard let thread = threadDetail else {
                return
            }
            self.threads[row] = thread
            DispatchQueue.main.async {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        })
        return cell
    }
}

extension ThreadsLoader {
    typealias Handler = () -> ()
    func loadNextBatch(completionHandler: @escaping Handler) {
        service.fetchNextBatch(forLabelId: labelId, withMaxResults: maxResults, completionHandler: {
            threadListResponse in
            defer {
                completionHandler()
            }
            guard let threads = threadListResponse?.threads else {
                return
            }
            self.threads.append(contentsOf: threads)
        })
    }
}
