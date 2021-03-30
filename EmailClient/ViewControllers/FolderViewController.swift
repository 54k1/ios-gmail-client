//
//  FolderViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import GoogleSignIn
import UIKit

class FolderViewController: UIViewController {
    // MARK: SubViews

    private let tableView = UITableView()
    private var refreshControl = UIRefreshControl()

    weak var threadSelectionDelegate: ThreadSelectionDelegate?
    private var label: (id: String, name: String)
    private let service: CachedGmailAPIService
    private var latestHistoryId: String?

    private let maxResults = 10
    private let threadsProvider: ThreadsLoader

    init(service: CachedGmailAPIService, label: (id: String, name: String)) {
        self.service = service
        self.label = label
        threadsProvider = ThreadsLoader(forLabelId: label.id, service: service)
        threadsProvider.table = tableView
        super.init(nibName: nil, bundle: nil)
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
}

extension FolderViewController {
    private func setupViews() {
        setupTableView()
        setupRefreshControl()
        setupLoadingFooter()
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
        tableView.dataSource = threadsProvider

        tableView.refreshControl = refreshControl
    }

    private func setupLoadingFooter() {
        let footer = UIView()
        tableView.addSubview(footer)
        footer.setConstant(height: 100).set(widthTo: tableView.widthAnchor)
        let spinner = UIActivityIndicatorView()
        footer.addSubview(spinner)
        spinner.center(in: footer)
        tableView.tableFooterView = footer
        spinner.startAnimating()
        tableView.tableFooterView?.isHidden = true
    }
}

extension FolderViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let thread = threadsProvider.getThread(atIndexPath: indexPath) else {
            NSLog("Thread did not load")
            return
        }
        threadSelectionDelegate?.didSelect(thread)
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 80
    }
}

extension FolderViewController {
    func startLoadingFooter() {
        tableView.tableFooterView?.isHidden = false
    }

    func stopLoadingFooter() {
        tableView.tableFooterView?.isHidden = true
    }
}

extension FolderViewController {
    func loadNextBatch() {
        startLoadingFooter()
    }
}

extension FolderViewController {
    @objc func partialSync() {
        threadsProvider.partialSync {
            [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
            }
        } onFailure: {
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshControl.endRefreshing()
            }
        }
    }
}

protocol ThreadSelectionDelegate: class {
    func didSelect(_ thread: ViewModel.Thread)
}
