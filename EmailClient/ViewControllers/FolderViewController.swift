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
        registerNotificationObservers()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    // MARK: Private

    private var label: (id: String, name: String)
    private let service: SyncService
    private var dataSource: TableViewDataSource<FolderViewController, ThreadMO>!
    private var syncHappening = false
    
    weak var threadSelectionDelegate: ThreadSelectionDelegate?
}


// MARK: Setup DataSource

extension FolderViewController {
    
    private func setupDataSource() {
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(tableView: tableView, delegate: self, frc: frc)
    }
    
    private var fetchRequest: NSFetchRequest<ThreadMO> {
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = ThreadMO.fetchRequestForLabel(withId: label.id, context: moc)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = 20
        return request
    }
}

// MARK: Setup Views

extension FolderViewController {
    private func setupViews() {
        setupTableView()
        setupRefreshControl()
        setupNavigationBar()
        view.backgroundColor = .white
    }
    
    private func setupNavigationBar() {
        title = label.name.capitalized
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(partialSync))
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeContentTitle = label.name.capitalized
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
    }
}

// MARK: Busy UI

extension FolderViewController {
    private func registerNotificationObservers() {
        // Busy UI to prevent multiple reloads
        NotificationCenter.default.addObserver(self, selector: #selector(enterBusyUI), name: .partialSyncDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitBusyUI), name: .partialSyncDidEnd, object: nil)
        
    }
    
    @objc private func enterBusyUI() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    @objc private func exitBusyUI() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
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
        guard !syncHappening else { return }
        syncHappening = true
        service.partialSync(completionHandler: {
            [weak self] response in
            print(response)
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                self?.syncHappening = false
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
