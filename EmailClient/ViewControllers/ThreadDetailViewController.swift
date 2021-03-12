//
//  ThreadViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import WebKit

class ThreadDetailViewController: UIViewController {
    // MARK: Properties

    var threadId: String!
    var threadDetail: ThreadDetail!
    var scrollHeight = [IndexPath: CGFloat]()
    var expandedCells = Set<IndexPath>()

    // MARK: Outlets

    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ThreadDetailTableViewCell.nibName, forCellReuseIdentifier: ThreadDetailTableViewCell.identifier)
        tableView.register(MessageHeaderTableViewCell.self, forCellReuseIdentifier: MessageHeaderTableViewCell.identifier)
        tableView.register(MessageFooterTableViewCell.nib, forCellReuseIdentifier: MessageFooterTableViewCell.identifier)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()

        Model.shared.fetchThreadDetail(withId: threadId, completionHandler: {
            threadDetail in
            self.threadDetail = threadDetail
            DispatchQueue.main.async {
                self.subjectLabel.text = threadDetail.messages[0].headerValueFor(key: "Subject")
                self.tableView.reloadData()
            }
        })
    }
}

extension ThreadDetailViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        threadDetail?.messages.count ?? 0
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        3
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (section, row) = (indexPath.section, indexPath.row)
        if row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageHeaderTableViewCell.identifier, for: indexPath) as! MessageHeaderTableViewCell
            cell.configure(with: threadDetail.messages[row])
            return cell
        } else if row == 1 {
            let cell = UINib(nibName: "ThreadDetailTableViewCell", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ThreadDetailTableViewCell
            cell.indexPath = indexPath
            cell.delegate = self

            render(threadDetail.messages[section], at: cell)
            return cell
        } else if row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageFooterTableViewCell.identifier, for: indexPath) as! MessageFooterTableViewCell
            return cell
        } else {
            fatalError("Each section of ThreadDetailView has only 3 rows(0, 1, 2); Row: \(row) requested")
        }
    }
}

extension ThreadDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = scrollHeight[indexPath] {
            return height
        }
        if expandedCells.contains(indexPath) {
            return 150
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let row = indexPath.row
        if row == 0 {
            if expandedCells.contains(indexPath) {
                expandedCells.remove(indexPath)
            } else {
                expandedCells.insert(indexPath)
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 20
    }
}

// MARK: Render

private extension ThreadDetailViewController {
    func render(_ message: UserMessage, at cell: ThreadDetailTableViewCell) {
        guard case let .success(component) = extract(message.payload!) else {
            // TODO: Render error popup
            print("failure")
            return
        }

        var alternative: Alternative!
        var attachments = [Attachment]()
        var htmlContent: Content!
        if let mixed = component as? Mixed {
            alternative = mixed.alternative
            attachments = mixed.attachments
        } else if let alt = component as? Alternative {
            alternative = alt
        } else if let content = component as? Content {
            htmlContent = content
        } else {
            NSLog("Cant interpret mime")
            return
        }

        if htmlContent == nil {
            guard let content = alternative.contents.first(where: {
                content in
                content.mimeType == "text/html"
            }) else {
                // Expect htmlContent to be present
                print("no html")
                return
            }
            htmlContent = content
        }

        cell.webView.loadHTMLString("<html><head><meta charset='utf8'><meta name = 'viewport' content = 'width=device-width'></head>" + htmlContent.data + "</html>", baseURL: nil)
    }
}

extension ThreadDetailViewController: ThreadDetailTableViewCellDelegate {
    func didCalculateHeightFor(_ cell: ThreadDetailTableViewCell, height: CGFloat) {
        // let indexPath = tableView.indexPath(for: cell)!
        let indexPath = cell.indexPath
        scrollHeight[indexPath!] = height + 50
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
}
