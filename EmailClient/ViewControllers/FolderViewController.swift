//
//  FolderViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import GoogleSignIn
import UIKit

enum FolderKind: String {
    case inbox = "INBOX", sent = "SENT", trash = "TRASH"
}

class ThreadListResponse: Codable {
    struct PartThread: Codable {
        let id: String
        var snippet: String
        let historyId: String
    }

    var threads: [PartThread]
    let resultSizeEstimate: Int
    let nextPageToken: String?
}

class ThreadDetail: Codable {
    var id: String
    var historyId: String
    var messages: [UserMessage]

    // For syncing
    func appendMessage(_ message: UserMessage) {
        messages.append(message)
        // As a result historyId is set to historyId of the message
        historyId = message.historyId
    }
    
    func deleteMessage(withId id: String) {
        messages.removeAll(where: {$0.id == id})
    }
}

class FolderViewController: UIViewController {
    // MARK: Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var refreshButton: UIButton!

    // MARK: Properties

    var kind: FolderKind = .inbox
    var threads: [ThreadListResponse.PartThread] {
        Model.shared.threads
    }

    var nextPageToken: String?
    var isFetchingNextBatch = true
    let batchSize = 10

    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshButton.addTarget(self, action: #selector(partialSync), for: .touchUpInside)
        tableView.tableFooterView = UIView()
        tableView.register(ThreadTableViewCell.nib, forCellReuseIdentifier: ThreadTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        refreshControl.attributedTitle = NSAttributedString(string: "Syncing")
        refreshControl.addTarget(self, action: #selector(partialSync), for: .valueChanged)
        tableView.refreshControl = refreshControl

        addLoadingFooter()

        title = kind.rawValue.capitalized
        isFetchingNextBatch = true
        Model.shared.fullSync(batchSize: batchSize, completionHandler: {
            _ in
            self.isFetchingNextBatch = false
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    func setKind(_ kind: FolderKind) {
        self.kind = kind
    }

    @IBSegueAction func showThreadDetail(_ coder: NSCoder, sender: Any?, segueIdentifier _: String?) -> ThreadDetailViewController? {
        let vc = ThreadDetailViewController(coder: coder)
        let cell = sender as! MessageTableViewCell
        vc?.threadId = cell.threadId
        return vc
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
        cell.threadId = thread.id
        cell.snippet = thread.snippet

        Model.shared.fetchThreadDetail(withId: thread.id, completionHandler: {
            threadDetail in
            DispatchQueue.main.async {
                cell.from = threadDetail.messages[0].from
            }
        })
        return cell
    }
}

extension FolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ThreadTableViewCell
        let threadId = cell.threadId
        let vc = storyboard?.instantiateViewController(identifier: "threadDetailVC") as! ThreadDetailViewController
        vc.threadId = threadId
        navigationController?.pushViewController(vc, animated: true)
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
    }
}

// Methods related to loading new batch once scrolled to bottom
extension FolderViewController: UIScrollViewDelegate {
    func loadNextBatch() {
        isFetchingNextBatch = true
        Model.shared.fetchNextThreadBatch(withSize: batchSize, completionHandler: {
            _ in
            self.isFetchingNextBatch = false
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isFetchingNextBatch else {
            return
        }
        let position = scrollView.contentOffset.y
        if position > (tableView.contentSize.height - 100 - scrollView.frame.height) {
            loadNextBatch()
        }
    }
}

extension FolderViewController {
    @objc func partialSync() {
        Model.shared.partialSync(folder: kind) {
            DispatchQueue.main.async {
                // TODO: Check
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                // self.tableView.reloadSections(IndexSet([0]), with: .automatic)
                // self.tableView.reloadData()
            }
        }
        refreshControl.endRefreshing()
    }
}
