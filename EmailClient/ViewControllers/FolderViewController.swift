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

    var label: (id: String, name: String)!
    var threads: [ThreadListResponse.PartThread] {
        Model.shared.threads
    }

    var isFetchingNextBatch = false
    var doneFetching = false
    let batchSize = 10
    let shouldFullSync = false

    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = label.name.capitalized
        setupViews()
        addLoadingFooter()
    }

    override func viewDidAppear(_: Bool) {
        tableView.reloadData()
    }
}

extension FolderViewController {
    private func setupViews() {
        setupTableView()
        view.backgroundColor = .white
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        Constraints.embed(tableView, in: view)
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension FolderViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        threads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath) as? ThreadTableViewCell else {
            return UITableViewCell()
        }

        let row = indexPath.row
        let thread = threads[row]
        Model.shared.fetchThreadDetail(withId: thread.id, completionHandler: {
            [weak cell]
            threadDetail in
            cell?.configure(with: threadDetail)
        })
        return cell
    }
}

extension FolderViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let threadId = threads[indexPath.row].id
        Model.shared.fetchThread(withId: threadId) {
            threadDetail in
            let vc = ThreadViewController()
            vc.configure(with: threadDetail)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 105
    }
}

extension FolderViewController {
    func addLoadingFooter() {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
        let spinner = UIActivityIndicatorView()
        spinner.center = footer.center
        spinner.startAnimating()
        footer.addSubview(spinner)
        tableView.tableFooterView = footer
        tableView.tableFooterView?.isHidden = true
    }
}

// Methods related to loading new batch once scrolled to bottom
extension FolderViewController: UIScrollViewDelegate {
    func loadNextBatch() {
        if doneFetching {
            return
        }
        isFetchingNextBatch = true
        tableView.tableFooterView?.isHidden = false
        Model.shared.fetchNextThreadBatch(withSize: batchSize, withLabelId: label.id, completionHandler: {
            threadListResponse in
            self.isFetchingNextBatch = false
            if threadListResponse.resultSizeEstimate == 0 {
                self.doneFetching = true
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.isHidden = false
                self.tableView.tableFooterView?.isHidden = true
            }
        })
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isFetchingNextBatch else {
            return
        }
        let position = scrollView.contentOffset.y
        if position > (tableView.contentSize.height - 100 - scrollView.frame.height), !doneFetching {
            loadNextBatch()
        }
    }
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

    func performInitialFullSync() {
        Model.shared.fullSync(batchSize: batchSize, withLabelId: label.id, completionHandler: {
            _ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
}
