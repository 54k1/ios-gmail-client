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
        let snippet: String
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
}

class FolderViewController: UIViewController {
    // MARK: Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var refreshButton: UIButton!

    // MARK: Properties

    var kind: FolderKind = .inbox
    // var messageBatch = [MessageList]()
    // var metaMessages = [MessageList.PartMessage]()
    var threads = [ThreadListResponse.PartThread]()
    var nextPageToken: String?
    var isFetchingNextBatch = false

    let batchSize = 10
    var paginating = false
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.register(ThreadTableViewCell.nib, forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        addLoadingFooter()

        title = kind.rawValue.capitalized
        // loadThreads()
        loadNextBatch()
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
            threadListResponse in
            self.threads.append(contentsOf: threadListResponse.threads)
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
