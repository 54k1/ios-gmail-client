//
//  FolderViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import GoogleSignIn
import UIKit

enum FolderKind: String {
    case inbox = "INBOX", sent = "SENT"
}

struct ThreadList: Codable {
    struct PartThread: Codable {
        let id: String
        let snippet: String
        let historyId: String
    }

    var threads: [PartThread]
    let resultSizeEstimate: Int
}

struct ThreadDetail: Codable {
    let id: String
    let historyId: String
    let messages: [UserMessage]
}

class FolderViewController: UIViewController {
    // MARK: Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var refreshButton: UIButton!

    // MARK: Properties

    var kind: FolderKind = .inbox
    var threadList: ThreadList!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(ThreadTableViewCell.nib, forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ThreadTableViewCell.self, forCellReuseIdentifier: "threadCell")

        refreshButton.addTarget(self, action: #selector(refreshTable), for: .touchUpInside)

        title = kind.rawValue.capitalized
        print("Folderkind=\(kind.rawValue)")
        Model.shared.fetchThreadList(withLabel: kind.rawValue) {
            threadList in
            self.threadList = threadList
            self.tableView.reloadData()
        }
    }

    @objc func refreshTable() {
        Model.shared.fetchThreadList(withLabel: kind.rawValue) {
            threadList in
            self.threadList = threadList
            self.tableView.reloadData()
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
        vc?.setThreadId(cell.threadId)
        return vc
    }
}

extension FolderViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        threadList?.threads.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(ThreadTableViewCell.nib)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath) as? ThreadTableViewCell else {
            return UITableViewCell()
        }

        let row = indexPath.row
        cell.snippet = threadList.threads[row].snippet
        cell.threadId = threadList.threads[row].id
        return cell
    }
}

extension FolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ThreadTableViewCell
        let threadID = cell.threadId
        let vc = storyboard?.instantiateViewController(identifier: "threadDetailVC") as! ThreadDetailViewController
        vc.setThreadId(threadID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
