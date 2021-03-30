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
    private lazy var nsfrc: NSFetchedResultsController<ThreadMO> = {
        let request: NSFetchRequest<ThreadMO> = ThreadMO.fetchRequest()
        request.predicate = NSPredicate(format: "SUBQUERY(messages, $m, ANY $m.labels.id LIKE %@).@count > 0", labelId)
        request.sortDescriptors = [NSSortDescriptor(key: "lastMessageDate", ascending: false)]
        request.fetchBatchSize = 20
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let nsfrc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        nsfrc.delegate = self
        return nsfrc
    } ()
    private let labelId: String
    private let maxResults = 10
    weak var table: UITableView?

    init(forLabelId labelId: String, service: CachedGmailAPIService) {
        self.service = service
        self.labelId = labelId
        super.init()
        initialLoad()
        setupFRC()
    }
    
    func setupFRC() {
        let didSaveNotification = NSManagedObjectContext.didSaveObjectsNotification
        NotificationCenter.default.addObserver(self, selector: #selector(didSave), name: didSaveNotification, object: nil)
    }
    
    @objc func didSave(_ notification: NSNotification) {
        initialLoad()
    }
}

extension ThreadsLoader {
    func getThread(atIndexPath indexPath: IndexPath) -> ViewModel.Thread? {
        guard indexPath.row < nsfrc.fetchedObjects?.count ?? 0 else {
            return nil
        }
        return .init(from: nsfrc.fetchedObjects![indexPath.row])
    }
}

extension ThreadsLoader {
    func partialSync(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        service.partialSync() {
            historyResponse in
            guard case let .success(success) = historyResponse else {
                onFailure()
                return
            }
            
            switch success {
            case .catchUp:
                print("have to catch up")
            case .upToDate:
                print("Up to Date")
            }
            DispatchQueue.main.async {
                self.table?.reloadData()
            }
            onSuccess()
        }
    }

    func initialLoad() {
        do {
            try nsfrc.performFetch()
        } catch let err {
            print(err)
        }
    }
}

extension ThreadsLoader: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        nsfrc.sections?.count ?? 0
    }
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        nsfrc.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath) as? ThreadTableViewCell else {
            return UITableViewCell()
        }

        let row = indexPath.row
        guard let threadMO = nsfrc.fetchedObjects?[row] else {
            fatalError("ThreadMO index out of range of nsfrc.fetchedObjects")
        }
        let threadVM = ViewModel.Thread(from: threadMO)
        cell.configure(with: threadVM)
        return cell
    }
}

extension ThreadsLoader: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
}
