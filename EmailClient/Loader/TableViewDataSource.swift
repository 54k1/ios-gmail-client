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
    associatedtype Cell: UITableViewCell
    associatedtype Object

    func configure(_ cell: Cell, with object: Object)
    var cellReuseIdentifier: String { get }
}

class TableViewDataSource<Delegate: TableViewDataSourceDelegate, Result: NSFetchRequestResult>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    typealias Cell = Delegate.Cell
    typealias Object = Delegate.Object

    init(tableView: UITableView, delegate: Delegate, frc: NSFetchedResultsController<Result>) {
        self.delegate = delegate
        self.frc = frc
        self.tableView = tableView
        super.init()
        tableView.dataSource = self
        try! frc.performFetch()
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {}

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        frc.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: delegate.cellReuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Cannot dequeue reusable cell with identifier: \(delegate.cellReuseIdentifier)")
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

    // MARK: Selected Object

    var selectedObject: Object? {
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return frc.object(at: indexPath) as? Object
    }
}
