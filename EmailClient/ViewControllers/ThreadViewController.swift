//
//  ThreadViewController.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import QuickLook
import UIKit
import WebKit

class ThreadViewController: UIViewController {
    // MARK: SubViews

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = 100
        tableView.estimatedRowHeight = 500
        // tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.identifier)
        tableView.register(MessageViewCell.self, forCellReuseIdentifier: MessageViewCell.reuseIdentifier)
        return tableView
    }()

    private let subjectHeader = UILabel()
    private let unselectedIndicatorLabel = UILabel()

    private var threadId: String!
    private var thread: GMailAPIService.Resource.Thread!
    private var heightForMessageWithId = [String: CGFloat]()
    private let extractor = MessageComponentExtractor()
    private let service: CachedGmailAPIService
    private let attachmentsLoader: AttachmentsLoader

    init(service: CachedGmailAPIService) {
        self.service = service
        attachmentsLoader = AttachmentsLoader(service: service)
        super.init(nibName: nil, bundle: nil)
        // addChild(previewController)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // tableView.tableHeaderView = subjectHeader
    }
}

extension ThreadViewController {
    func setupViews() {
        view.backgroundColor = .white
        setupTableView()
        setupHeaderView()
        setupEmptyView()
        addConstraints()
    }

    func addConstraints() {
        tableView.embed(in: view.safeAreaLayoutGuide)
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = nil
        tableView.tableHeaderView = nil
        tableView.tableHeaderView = subjectHeader
    }

    func setupHeaderView() {
        view.addSubview(subjectHeader)
        subjectHeader.translatesAutoresizingMaskIntoConstraints = false
        subjectHeader.numberOfLines = 0
        // subjectHeader.attributedText = NSAttributedString(string: threadDetail.messages[0].headerValueFor(key: "Subject")!, attributes: [
        //    .strokeColor: UIColor.black,
        //    .font: UIFont.boldSystemFont(ofSize: 30),
        // ])
    }

    private func setupEmptyView() {
        unselectedIndicatorLabel.text = "Select a thread to view"
        view.addSubview(unselectedIndicatorLabel)
        unselectedIndicatorLabel.center(in: view)
    }
}

extension ThreadViewController {
    func configure(with thread: GMailAPIService.Resource.Thread) {
        self.thread = thread
        // Fetch attachments too
        unselectedIndicatorLabel.isHidden = true
        title = thread.messages?.first?.snippet
        tableView.reloadData()
    }
}

extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        thread?.messages?.count ?? 0
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = thread.messages?[indexPath.section] else {
            fatalError("Message for indexPath: \(indexPath) not available")
        }
        let cell = MessageViewCell()
        cell.delegate = self
        cell.messageId = message.id
        cell.configure(from: message.fromName!)

        extractor.extract(from: message) {
            [weak cell]
            htmlString, attachments in
            guard let cell = cell else {
                return
            }
            DispatchQueue.main.async {
                cell.configure(withHTML: htmlString, attachmentCount: attachments?.count ?? 0)
                guard let attachments = attachments else {return}
                self.attachmentsLoader.loadAttachments(attachments, forMessageWithId: message.id, completionHandler: {
                    attachments in
                    cell.attachments = attachments
                })
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let messageId = thread.messages![indexPath.row].id
        guard heightForMessageWithId[messageId] == nil, let cell = tableView.cellForRow(at: indexPath) as? MessageViewCell else {
            if heightForMessageWithId[messageId] != nil {
                NSLog("cellForRow(at:) returned nil")
            }
            return
        }
        heightForMessageWithId[messageId] = cell.height
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let messageId = thread.messages![indexPath.row].id
        if let height = heightForMessageWithId[messageId] {
            return height
        }
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        10
    }
}

extension ThreadViewController: ThreadSelectionDelegate {
    func didSelect(_ thread: GMailAPIService.Resource.Thread) {
        configure(with: thread)
    }
}

extension ThreadViewController: CollectionViewDelegate {
    func didSelectItemAt(_ indexPath: IndexPath, attachments: [Attachment]?) {
        
        let previewController = FileViewController(attachments: attachments!)
        previewController.currentPreviewItemIndex = indexPath.row
        navigationController?.pushViewController(previewController, animated: true)
    }
}
