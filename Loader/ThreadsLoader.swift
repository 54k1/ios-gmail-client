//
//  ThreadsLoader.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import CoreData
import Foundation
import UIKit

class ThreadsLoader: NSObject {
    private let service: CachedGmailAPIService
    private let labelId: String
    private let maxResults = 10
    weak var table: UITableView?
    private var threads = [ViewModel.Thread]()

    init(forLabelId labelId: String, service: CachedGmailAPIService) {
        self.service = service
        self.labelId = labelId
    }
}

extension ThreadsLoader {
    func getThread(atIndexPath indexPath: IndexPath) -> ViewModel.Thread? {
        guard indexPath.row < threads.count else {
            return nil
        }
        return threads[indexPath.row]
        // return ViewModel.Thread(from: threads[indexPath.row])
    }
}

extension ThreadsLoader {
    func partialSync(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        service.partialSync(andReturnThreadsWithLabelId: labelId) {
            [weak self]
            historyResponse in
            guard case let .success(success) = historyResponse else {
                onFailure()
                return
            }
            guard case let .catchUp(threads) = success else {
                print("Up to date")
                onSuccess()
                return
            }
            // self?.threads = threads
            DispatchQueue.main.async {
                self?.table?.reloadData()
            }
            onSuccess()
        }
    }

    func initialLoad() {
        service.localThreadsSyncOrFullSync(forLabelId: labelId, withMaxResults: maxResults) {
            threadVMs in
            self.threads = threadVMs
            DispatchQueue.main.async {
                self.table?.reloadData()
            }
        }
    }

    func fetchNextBatch() {
        service.fetchNextBatch(forLabelId: labelId, withMaxResults: maxResults) {
            threadVMs in
            self.threads = threadVMs
        }
    }
}

extension ThreadsLoader: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        threads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath) as? ThreadTableViewCell else {
            return UITableViewCell()
        }

        let row = indexPath.row
        let threadVM = threads[row]
        cell.configure(with: threadVM)
        return cell
    }
}
