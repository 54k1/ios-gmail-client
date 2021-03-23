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

    private let tableView: UITableView = {
        let view = UITableView()
        view.tableFooterView = UIView()
        view.register(ThreadTableViewCell.self, forCellReuseIdentifier: ThreadTableViewCell.identifier)

        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Syncing")
        refreshControl.addTarget(self, action: #selector(partialSync), for: .valueChanged)

        view.refreshControl = refreshControl
        return view
    }()

    weak var threadSelectionDelegate: ThreadSelectionDelegate?
    private var label = (id: "INBOX", name: "inbox")
    private var threads = [GMailAPIService.Resource.Thread]()
    private let service: CachedGmailAPIService
    private var latestHistoryId: String?

    private let maxResults = 10
    let threadsProvider: ThreadsLoader

    var refreshControl = UIRefreshControl()

    init(service: CachedGmailAPIService, label: (id: String, name: String)) {
        self.service = service
        self.label = label
        threadsProvider = ThreadsLoader(forLabelId: label.id, service: service)
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

        loadNextBatch()
    }
}

extension FolderViewController {
    private func setupViews() {
        setupTableView()
        setupLoadingFooter()
        view.backgroundColor = .white
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        Constraints.embed(tableView, in: view)
        tableView.delegate = self
        tableView.dataSource = threadsProvider
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
    func setupLoadingFooter() {
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

    func startLoadingFooter() {
        tableView.tableFooterView?.isHidden = false
    }

    func stopLoadingFooter() {
        tableView.tableFooterView?.isHidden = true
    }
}

// Methods related to loading new batch once scrolled to bottom
extension FolderViewController: UIScrollViewDelegate {
    func loadNextBatch() {
        startLoadingFooter()
        threadsProvider.loadNextBatch {
            DispatchQueue.main.async {
                self.stopLoadingFooter()
                self.tableView.reloadData()
            }
        }
    }

//    func loadNextBatch() {
//        if doneFetching {
//            return
//        }
//        isFetchingNextBatch = true
//        tableView.tableFooterView?.isHidden = false
//        Model.shared.fetchNextThreadBatch(withSize: batchSize, withLabelId: label.id, completionHandler: {
//            threadListResponse in
//            self.isFetchingNextBatch = false
//            if threadListResponse.resultSizeEstimate == 0 {
//                self.doneFetching = true
//            }
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//                self.tableView.isHidden = false
//                self.tableView.tableFooterView?.isHidden = true
//            }
//        })
//    }

//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard !isFetchingNextBatch else {
//            return
//        }
//        let position = scrollView.contentOffset.y
//        if position > (tableView.contentSize.height - 100 - scrollView.frame.height), !doneFetching {
//            loadNextBatch()
//        }
//    }
}

extension FolderViewController {
    @objc func partialSync() {
        Model.shared.partialSync(withLabelId: label.id) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        refreshControl.endRefreshing()
    }

    func refresh() {
        service.partialSync(forLabelId: label.id) {
            _ in
            // At the top again
        }
    }

    func initialLoad() {
        service.localThreadsSync(forLabelId: label.id, maxResults: maxResults, completionHandler: {
            threadListResponse in
            if threadListResponse == nil {
                service.listThreads(withLabelId: label.id, withMaxResults: maxResults, completionHandler: {
                    threadListResponse in
                    guard let threadListResponse = threadListResponse else {
                        // Could not fetch
                        return
                    }
                    if let threads = threadListResponse.threads {
                        self.threads = threads
                    }
                })
            }
        })
    }
}

protocol ThreadSelectionDelegate: class {
    func didSelect(_ thread: GMailAPIService.Resource.Thread)
}
