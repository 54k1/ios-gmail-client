//
//  TableViewDataSource.swift
//  EmailClient
//
//  Created by SV on 02/04/21.
//

import UIKit
import CoreData
import Foundation

protocol TableViewDataSourceDelegate {
    associatedtype Cell: ReusableCell
    associatedtype Object

    func configure(_ cell: Cell, with object: Object)
}

class TableViewDataSource<Delegate: TableViewDataSourceDelegate, Result: NSFetchRequestResult>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    typealias Cell = Delegate.Cell
    typealias Object = Delegate.Object

    init(tableView: UITableView, delegate: Delegate, frc: NSFetchedResultsController<Result>) {
        self.frc = frc
        self.delegate = delegate
        self.tableView = tableView
        
        super.init()
        
        setupTableView()
        setupFRC()
    }
    
    private func setupTableView() {
        tableView?.dataSource = self
    }
    
    private func setupFRC() {
        frc.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSManagedObjectContext.didSaveObjectsNotification, object: nil)
        try! frc.performFetch()
        
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("type=\(type)")
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else {fatalError("newIndexPath must not be nil")}
            tableView?.insertRows(at: [indexPath], with: .automatic)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {fatalError("indexPath, newIndexPath must not be nil")}
            tableView?.moveRow(at: indexPath, to: newIndexPath)
        case .delete:
            guard let indexPath = indexPath else {fatalError("indexPath must not be nil")}
            tableView?.deleteRows(at: [indexPath], with: .automatic)
        case .update:
            ()
            // guard let indexPath = indexPath else {fatalError("indexPath must not be nil")}
            // tableView?.cellForRow(at: indexPath)
        @unknown default:
            fatalError("Unknown NSFetchedResultsChangeType")
        }
    }

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc.sections?[0].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Cannot dequeue reusable cell with identifier: \(Cell.reuseIdentifier)")
        }

        guard let object = frc.object(at: indexPath) as? Object else {
            fatalError("Cannot cast NSFetchRequestResult to Object")
        }

        delegate.configure(cell, with: object)
        return cell
    }

    // MARK: Private

    private let delegate: Delegate
    private let frc: NSFetchedResultsController<Result>
    private weak var tableView: UITableView?
    
    
    @objc private func refresh() {
        try! frc.performFetch()
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }

    // MARK: Selected Object

    var selectedObject: Object? {
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return frc.object(at: indexPath) as? Object
    }
}
