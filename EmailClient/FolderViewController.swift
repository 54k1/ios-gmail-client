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

    let batchSize = 40
    var paginating = false
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.register(ThreadTableViewCell.nib, forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        addLoadingFooter()
        refreshButton.addTarget(self, action: #selector(refreshTable), for: .touchUpInside)

        title = kind.rawValue.capitalized
        loadThreads()
        // loadThreads()

        // Model.shared.fullSync() {
        //     threadList in
        //     self.threads.append(contentsOf: threadList.threads)
        // Model.shared.fetchThreadList(withLabel: self.kind.rawValue, withToken: nil, maxResults: self.batchSize) {
        //     threadList in
        //     self.threads.append(contentsOf: threadList.threads)
        //     self.nextPageToken = threadList.nextPageToken
        //     DispatchQueue.main.async {
        //         self.tableView.reloadData()
        //     }
        // }
        // }
    }

    @objc func refreshTable() {
        print("refresh")
        Model.shared.partialSync(of: kind, type: .messageAdded) {
            addedPartMessages in
            for partMessage in addedPartMessages {
                Model.shared.fetchMessage(withId: partMessage.id) {
                    _ in ()
                }
            }
            // Model.shared.partialSync(of: self.kind, type: .messageDeleted) {
            //     deletedPartMessages in
            //     for deleted in deletedPartMessages {
            //         let index = self.metaMessages.firstIndex(where: {
            //             partMessage in
            //             partMessage.id == deleted.id
            //         })
            //         self.metaMessages.remove(at: index!)
            //     }
            //     DispatchQueue.main.async {
            //         self.tableView.reloadData()
            //     }
            // }
        }
    }

    func setKind(_ kind: FolderKind) {
        self.kind = kind
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */

    @IBSegueAction func showThreadDetail(_ coder: NSCoder, sender: Any?, segueIdentifier _: String?) -> ThreadDetailViewController? {
        let vc = ThreadDetailViewController(coder: coder)
        let cell = sender as! MessageTableViewCell
        vc?.threadId = cell.threadId
        return vc
    }

    func loadNextBatch() {
        // if let nextPageToken = nextPageToken { Model.shared.fetchThreadList(withLabel: kind.rawValue, withToken: nextPageToken, maxResults: batchSize) { threadList in self.batch.append(threadList) DispatchQueue.main.async {
        //             self.tableView.reloadData()
        //         }
        //     }
        // }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
}

extension FolderViewController {
    func loadThreads() {
        Model.shared.fetchThreadList(withLabel: kind.rawValue, withToken: nextPageToken, maxResults: batchSize) {
            threadList in
            self.threads.append(contentsOf: threadList.threads)
            self.nextPageToken = threadList.nextPageToken
            DispatchQueue.main.async {
                self.paginating = false
                self.tableView.tableFooterView = nil
                self.tableView.reloadData()
            }
        }
    }

    func addLoadingFooter() {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
        let spinner = UIActivityIndicatorView()
        spinner.center = footer.center
        spinner.startAnimating()
        footer.addSubview(spinner)
        tableView.tableFooterView = footer
    }
}
