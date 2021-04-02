//
//  FolderViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import CoreData
import GoogleSignIn
import UIKit

class FolderViewController: UIViewController {
    
    // MARK: SubViews
    
    private let tableView = UITableView()
    private var refreshControl = UIRefreshControl()

    init(service: SyncService, label: (id: String, name: String)) {
        self.service = service
        self.label = label
        super.init(nibName: nil, bundle: nil)

        setupDataSource()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = label.name.capitalized
        setupViews()
    }

    // MARK: Private

    private var label: (id: String, name: String)
    private let service: SyncService
    private var dataSource: TableViewDataSource<FolderViewController, ThreadMO>!
    
    weak var threadSelectionDelegate: ThreadSelectionDelegate?
}

// MARK: Setup DataSource

extension FolderViewController {
    private func setupDataSource() {
        let request = ThreadMO.sortedFetchRequest
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(tableView: tableView, delegate: self, frc: frc)
    }
}

// MARK: Setup Views

extension FolderViewController {
    private func setupViews() {
        setupTableView()
        setupRefreshControl()
        view.backgroundColor = .white
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(partialSync), for: .valueChanged)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.embed(in: view.safeAreaLayoutGuide)
        tableView.tableFooterView = UIView()
        tableView.register(ThreadTableViewCell.self, forCellReuseIdentifier: ThreadTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.refreshControl = refreshControl
    }
}

// MARK: UITableViewDelegate

extension FolderViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt _: IndexPath) {
        guard let thread = dataSource.selectedObject else {
            NSLog("Unable to retreive selected thread in table")
            return
        }

        let vm = ViewModel.Thread(from: thread)
        threadSelectionDelegate?.didSelect(vm)
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: Refresh

extension FolderViewController {
    @objc private func partialSync() {
        service.partialSync(completionHandler: {
            [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
            }
        })
    }
}

protocol ThreadSelectionDelegate: class {
    func didSelect(_ thread: ViewModel.Thread)
}

extension FolderViewController: TableViewDataSourceDelegate {
    typealias Cell = ThreadTableViewCell
    typealias Object = ThreadMO
    
    var cellReuseIdentifier: String {
        ThreadTableViewCell.identifier
    }

    func configure(_ cell: ThreadTableViewCell, with object: ThreadMO) {
        let threadVM = ViewModel.Thread(from: object)
        cell.configure(with: threadVM)
    }
}
