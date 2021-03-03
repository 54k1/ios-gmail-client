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

    // MARK: Outlets

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ThreadDetailTableViewCell.nibName, forCellReuseIdentifier: ThreadDetailTableViewCell.identifier)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

        Model.shared.fetchThreadDetail(withId: threadId, completionHandler: {
            threadDetail in
            self.threadDetail = threadDetail
            DispatchQueue.main.async {
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
        // Just webview displaying content, (header, footer) are seperate
        1
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bundle = Bundle(for: ThreadDetailTableViewCell.self)
        let nibName = String(describing: ThreadDetailTableViewCell.self)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let cell = UINib(nibName: "ThreadDetailTableViewCell", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ThreadDetailTableViewCell
        cell.indexPath = indexPath
        // let cell = tableView.dequeueReusableCell(withIdentifier: ThreadDetailTableViewCell.identifier, for: indexPath) as! ThreadDetailTableViewCell
        cell.delegate = self

        let section = indexPath.section
        render(threadDetail.messages[section], at: cell)
        // cell.html = threadDetail.messages[section]

        return cell
    }
}

extension ThreadDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "From \(threadDetail.messages[section].from!)"
        return label
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let label = UILabel()
        label.text = "Reply"
        return label
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = scrollHeight[indexPath] {
            return height
        }
        return UITableView.automaticDimension
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
