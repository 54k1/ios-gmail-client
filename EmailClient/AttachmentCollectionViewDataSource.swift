//
//  AttachmentCollectionViewDataSource.swift
//  EmailClient
//
//  Created by SV on 31/03/21.
//

import CoreData
import Foundation
import UIKit

protocol AttachmentViewDataSourceDelegate: class {
    associatedtype Cell: UICollectionViewCell
    associatedtype Object: NSManagedObject
    func configure(_ cell: Cell, with object: Object)
}

class AttachmentViewDataSource<Result: NSFetchRequestResult, Delegate: AttachmentViewDataSourceDelegate>: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    typealias Object = Delegate.Object
    typealias Cell = Delegate.Cell

    required init(collectionView: UICollectionView, cellIdentifier: String, fetchedResultsController: NSFetchedResultsController<Result>, delegate: Delegate) {
        self.collectionView = collectionView
        self.cellIdentifier = cellIdentifier
        self.fetchedResultsController = fetchedResultsController
        self.delegate = delegate
        super.init()
        fetchedResultsController.delegate = self

        try? fetchedResultsController.performFetch()
    }

    // MARK: Private

    private let collectionView: UICollectionView
    private let cellIdentifier: String
    private let fetchedResultsController: NSFetchedResultsController<Result>
    private weak var delegate: Delegate?

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! Cell
        let object = fetchedResultsController.object(at: indexPath) as! Object
        delegate?.configure(cell, with: object)
        return cell
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will change")
    }

    func controller(_: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at _: IndexPath?, for _: NSFetchedResultsChangeType, newIndexPath _: IndexPath?) {
        print("didChange1")
        let attachmentMO = anObject as! AttachmentMO
        guard attachmentMO.location == nil else {
            // location already set
            return
        }
    }

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        print("didChange")
        collectionView.reloadData()
    }
}
