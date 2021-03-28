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
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.rowHeight = 100
        tableView.estimatedRowHeight = 500
        tableView.register(MessageViewCell.self, forCellReuseIdentifier: MessageViewCell.reuseIdentifier)
        return tableView
    }()

    private let subjectHeader = UILabel()
    private let unselectedIndicatorLabel = UILabel()

    private var threadId: String?
    // private var thread: GMailAPIService.Resource.Thread?
    private var heightForMessageWithId = [String: CGFloat]()
    private let extractor = MessageComponentExtractor()
    private let service: CachedGmailAPIService
    private let attachmentsLoader: AttachmentsLoader
    private var selectedMessageIds = Set<String>()
    private var extractedMessages = [MessageComponentExtractor.Message]()
    private var messages = [ViewModel.Message]()
    private var threadVM: ViewModel.Thread?

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
    }
}

extension ThreadViewController {
    func setupViews() {
        view.backgroundColor = .white
        setupHeaderView()
        setupTableView()
        setupEmptyView()
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = subjectHeader
        tableView.embed(in: view.safeAreaLayoutGuide)
    }

    func setupHeaderView() {
        view.addSubview(subjectHeader)
        subjectHeader.numberOfLines = 0
        subjectHeader
            .alignLeading(to: view.safeAreaLayoutGuide.leadingAnchor, withPadding: 20)
            .alignTrailing(to: view.safeAreaLayoutGuide.trailingAnchor, withPadding: -20)
            .setConstant(height: 100)
        subjectHeader.font = .systemFont(ofSize: 20, weight: .semibold)
    }

    private func setupEmptyView() {
        unselectedIndicatorLabel.text = "Select a thread to view"
        view.addSubview(unselectedIndicatorLabel)
        unselectedIndicatorLabel.center(in: view)
    }
}

extension ThreadViewController {
    func configure(with thread: GMailAPIService.Resource.Thread) {
        // self.thread = thread
        title = thread.messages?.first?.snippet
        subjectHeader.text = thread.messages?.first?.headerValueFor(key: "Subject")
        guard let messages = thread.messages else {
            NSLog("No messages")
            return
        }
        extractedMessages.removeAll()
        for message in messages {
            let result = extractor.extract(from: message)
            guard case let .success(success) = result else {
                return
            }
            extractedMessages.append(success)
            for attachmentMetaData in success.attachments {
                attachmentsLoader.loadAttachment(withMetaData: attachmentMetaData, completionHandler: {
                    [weak self]
                    _ in
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                })
            }
        }
        unselectedIndicatorLabel.isHidden = true
        tableView.reloadData()
    }

    func configure(with threadVM: ViewModel.Thread) {
        title = threadVM.messages.first?.subject
        subjectHeader.text = title
        self.threadVM = threadVM
        unselectedIndicatorLabel.isHidden = true
        tableView.reloadData()
    }
}

extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        threadVM?.messages.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageViewCell.reuseIdentifier, for: indexPath) as? MessageViewCell else {
            fatalError("\(MessageViewCell.reuseIdentifier) for indexPath: \(indexPath) not available")
        }

        cell.delegate = self
        cell.attachmentsLoader = attachmentsLoader
        cell.configure(with: threadVM!.messages[indexPath.row])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let messageId = threadVM!.messages[indexOfThread(withIndexPath: indexPath)].id
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageViewCell else {
            NSLog("cellForRow(at:) returned nil")
            return
        }
        heightForMessageWithId[messageId] = cell.height
        if selectedMessageIds.contains(messageId) {
            selectedMessageIds.remove(messageId)
        } else {
            selectedMessageIds.insert(messageId)
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let messageId = threadVM!.messages[indexOfThread(withIndexPath: indexPath)].id
        if selectedMessageIds.contains(messageId), let height = heightForMessageWithId[messageId] {
            return height
        }
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        10
    }

    private func indexOfThread(withIndexPath indexPath: IndexPath) -> Int {
        indexPath.row
    }
}

extension ThreadViewController: ThreadSelectionDelegate {
    func didSelect(_ thread: ViewModel.Thread) {
        configure(with: thread)
    }
}

extension ThreadViewController: CollectionViewDelegate {
    func didSelectItemAt(_ indexPath: IndexPath, attachmentsMetaData: [MessageComponentExtractor.AttachmentMetaData]?) {
        let previewController = FileViewController(loader: attachmentsLoader, attachments: attachmentsMetaData!)
        previewController.currentPreviewItemIndex = indexPath.row
        navigationController?.pushViewController(previewController, animated: true)
    }
}
