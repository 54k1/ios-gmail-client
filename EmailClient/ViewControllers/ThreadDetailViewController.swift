//
//  ThreadDetailViewController.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import CoreData
import UIKit
import WebKit

class ThreadDetailViewController: UIViewController {
    // MARK: SubViews

    private var tableView: UITableView!
    private var subjectHeader: UILabel!
    private var unselectedIndicatorLabel: UILabel!

    init(service: SyncService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    // MARK: Private

    private var heightForMessageWithId = [String: CGFloat]()
    private let extractor = MessageComponentExtractor()
    private let service: SyncService
    private var selectedMessageIds = Set<String>()
    private var messages = [ViewModel.Message]()
    private var threadVM: ViewModel.Thread?
    private var threadMO: ThreadMO?
    private var attachmentDataSource = [String: CollectionViewDataSource<AttachmentMO, ThreadDetailViewController>]()
}

// MARK: SetupViews

extension ThreadDetailViewController {
    private func setupViews() {
        setupHeaderView()
        setupTableView()
        setupEmptyView()
        setupNavigationBar()
        view.backgroundColor = .systemBackground
    }

    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        view.addSubview(tableView)
        tableView.rowHeight = 100
        tableView.estimatedRowHeight = 500
        tableView.register(MessageViewCell.self, forCellReuseIdentifier: MessageViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = subjectHeader
        tableView.embed(in: view.safeAreaLayoutGuide)
    }

    private func setupHeaderView() {
        subjectHeader = UILabel()
        subjectHeader.numberOfLines = 0
        subjectHeader.font = .systemFont(ofSize: 20, weight: .semibold)
    }

    private func setupEmptyView() {
        unselectedIndicatorLabel = UILabel()
        unselectedIndicatorLabel.text = "Select a thread to view"
        unselectedIndicatorLabel.numberOfLines = 0
        view.addSubview(unselectedIndicatorLabel)
        unselectedIndicatorLabel.center(in: view)
        unselectedIndicatorLabel.isHidden = (threadMO != nil)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.backgroundColor = .systemBackground
    }
}

// MARK: Configure

extension ThreadDetailViewController {
    private func configure(with threadVM: ViewModel.Thread) {
        self.threadVM = threadVM
    }

    func configure(with threadMO: ThreadMO) {
        hideUnselectedIndicator()
        self.threadMO = threadMO
        threadVM = .init(from: threadMO)
        reloadData()
    }

    private func reloadData() {
        title = threadVM?.messages.first?.subject
        subjectHeader?.text = title ?? "No Subject"
        tableView?.reloadData()
    }

    private func hideUnselectedIndicator() {
        unselectedIndicatorLabel?.isHidden = true
    }
}

// MARK: Table Data Source

extension ThreadDetailViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        threadMO?.messages.count ?? 0
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Check bug(autolayout issues when reusing cells)
        // guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageViewCell.reuseIdentifier, for: indexPath) as? MessageViewCell else {
        //     fatalError("\(MessageViewCell.reuseIdentifier) for indexPath: \(indexPath) not available")
        // }
        let cell = MessageViewCell()

        cell.configure(with: threadVM!.messages[indexOfMessage(indexPath)])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let messageId = threadVM!.messages[indexOfMessage(indexPath)].id
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
        let messageId = threadVM!.messages[indexOfMessage(indexPath)].id
        if selectedMessageIds.contains(messageId), let height = heightForMessageWithId[messageId] {
            return height
        }
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        10
    }

    private func indexOfMessage(_ indexPath: IndexPath) -> Int {
        indexPath.section
    }
}

// MARK: Table View Delegate

extension ThreadDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let message = threadMO?.messages.array[section] as! MessageMO
        guard message.attachments?.count ?? 0 > 0 else { return nil }

        let messageId = message.id
        let attachmentsView = AttachmentsView()
        attachmentsView.collectionView.tag = section
        attachmentsView.collectionView.delegate = self

        guard let dataSource = attachmentDataSource[messageId] else {
            let request = AttachmentMO.fetchRequest(for: messageId)
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            let dataSource = CollectionViewDataSource(collectionView: attachmentsView.collectionView, fetchedResultsController: frc, delegate: self)
            attachmentsView.setCollectionViewDataSource(dataSource)
            attachmentDataSource[messageId] = dataSource
            return attachmentsView
        }

        attachmentsView.collectionView.dataSource = dataSource

        return attachmentsView
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard threadVM?.messages[section].attachments.count ?? 0 > 0 else {
            return 0
        }
        return 130
    }
}

extension ThreadDetailViewController: ThreadSelectionDelegate {
    func didSelect(_ thread: ThreadMO) {
        configure(with: thread)
    }
}

extension ThreadDetailViewController: CollectionViewDataSourceDelegate {
    typealias Cell = AttachmentCollectionViewCell
    typealias Object = AttachmentMO

    func configure(_ cell: AttachmentCollectionViewCell, with object: AttachmentMO) {
        let attachmentVM = ViewModel.Attachment(from: object)
        cell.configure(with: attachmentVM)
    }
}

// MARK: Collection View Delegate

extension ThreadDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt _: IndexPath) {
        let section = collectionView.tag
        print("tag=\(section)")
        let vc = AttachmentPreviewController(message: threadMO!.messages[section] as! MessageMO)
        navigationController?.pushViewController(vc, animated: true)
    }
}
