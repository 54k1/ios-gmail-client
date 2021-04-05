//
//  CollectionViewDataSource.swift
//  EmailClient
//
//  Created by SV on 31/03/21.
//

import CoreData
import Foundation
import UIKit

protocol ReuseableCell: UICollectionViewCell {
    static var reuseIdentifier: String { get }
}

protocol CollectionViewDataSourceDelegate: class {
    associatedtype Cell: ReuseableCell
    associatedtype Object: NSManagedObject
    func configure(_ cell: Cell, with object: Object)
}

class CollectionViewDataSource<Result: NSFetchRequestResult, Delegate: CollectionViewDataSourceDelegate>: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    typealias Object = Delegate.Object
    typealias Cell = Delegate.Cell

    required init(collectionView: UICollectionView, fetchedResultsController: NSFetchedResultsController<Result>, delegate: Delegate) {
        self.collectionView = collectionView
        self.fetchedResultsController = fetchedResultsController
        self.delegate = delegate
        super.init()
        fetchedResultsController.delegate = self
        collectionView.dataSource = self

        try! fetchedResultsController.performFetch()
    }

    // MARK: Private

    private let collectionView: UICollectionView
    private let fetchedResultsController: NSFetchedResultsController<Result>
    private weak var delegate: Delegate?

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        let object = fetchedResultsController.object(at: indexPath) as! Object
        delegate?.configure(cell, with: object)
        return cell
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        let cnt = fetchedResultsController.fetchedObjects?.count ?? 0
        return cnt
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
