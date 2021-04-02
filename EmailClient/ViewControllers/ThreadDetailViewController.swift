//
//  ThreadDetailViewController.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import UIKit
import WebKit
import CoreData
import QuickLook

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
    }

    // MARK: Private

    private var heightForMessageWithId = [String: CGFloat]()
    private let extractor = MessageComponentExtractor()
    private let service: SyncService
    private var selectedMessageIds = Set<String>()
    private var messages = [ViewModel.Message]()
    private var threadVM: ViewModel.Thread?
    private var attachmentDataSource = [String: AttachmentViewDataSource<AttachmentMO, ThreadDetailViewController>]()
    private let attachmentsLoader: AttachmentsLoader! = nil
}

// MARK: SetupViews

extension ThreadDetailViewController {
    private func setupViews() {
        setupHeaderView()
        setupTableView()
        setupEmptyView()

        view.backgroundColor = .white
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
        view.addSubview(subjectHeader)
        subjectHeader.numberOfLines = 0
        subjectHeader
            .alignLeading(to: view.safeAreaLayoutGuide.leadingAnchor, withPadding: 20)
            .alignTrailing(to: view.safeAreaLayoutGuide.trailingAnchor, withPadding: -20)
            .setConstant(height: 100)
        subjectHeader.font = .systemFont(ofSize: 20, weight: .semibold)
    }

    private func setupEmptyView() {
        unselectedIndicatorLabel = UILabel()
        unselectedIndicatorLabel.text = "Select a thread to view"
        view.addSubview(unselectedIndicatorLabel)
        unselectedIndicatorLabel.center(in: view)
    }
}

// MARK: Configure

extension ThreadDetailViewController {
    func configure(with threadVM: ViewModel.Thread) {
        self.threadVM = threadVM
        title = threadVM.messages.first?.subject
        subjectHeader.text = title
        unselectedIndicatorLabel.isHidden = true
        tableView.reloadData()
    }

    private func loadAttachments() {
        service.downloadAttachments(for: threadVM!.id)
    }
}

extension ThreadDetailViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        threadVM?.messages.count ?? 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Check bug(autolayout issues when reusing cells)
        // guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageViewCell.reuseIdentifier, for: indexPath) as? MessageViewCell else {
        //     fatalError("\(MessageViewCell.reuseIdentifier) for indexPath: \(indexPath) not available")
        // }
        let cell = MessageViewCell()

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

extension ThreadDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard threadVM?.messages[section].attachments.count ?? 0 > 0, let messageId = threadVM?.messages[section].id else {
            return nil
        }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        // collectionView.set(widthTo: tableView.widthAnchor).setConstant(height: 100)
        collectionView.register(AttachmentCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let request = AttachmentMO.fetchRequest(for: messageId)
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        let dataSource = AttachmentViewDataSource(collectionView: collectionView, cellIdentifier: "cell", fetchedResultsController: frc, delegate: self)
        attachmentDataSource[messageId] = dataSource
        collectionView.dataSource = dataSource
        collectionView.backgroundColor = .lightGray

        let view = UITableViewHeaderFooterView()
        // view.setConstant(width: 100).setConstant(height: 100)
        view.addSubview(collectionView)
        collectionView.embed(in: view.safeAreaLayoutGuide)
        return view
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard threadVM?.messages[section].attachments.count ?? 0 > 0 else {
            return 0
        }
        return 100
    }
}

extension ThreadDetailViewController: ThreadSelectionDelegate {
    func didSelect(_ thread: ViewModel.Thread) {
        configure(with: thread)
    }
}

extension ThreadDetailViewController: AttachmentViewDataSourceDelegate {
    typealias Cell = AttachmentCollectionViewCell
    typealias Object = AttachmentMO

    func configure(_ cell: AttachmentCollectionViewCell, with object: AttachmentMO) {
        let attachmentVM = ViewModel.Attachment(from: object)
        cell.configure(with: attachmentVM)

        guard object.location == nil else {
            return
        }
        // Download attachment
    }

    private func downloadAttachment(withId attachmentId: String, withMessageId messageId: String) {
        attachmentsLoader.downloadAttachment(withId: attachmentId, withMessageId: messageId) {
            urlOptional in
            guard let url = urlOptional else {
                return
            }
            self.attachmentsLoader.generatePreviewThumbnail(forFileAt: url) {
                imageOptional in
                guard let image = imageOptional else {
                    return
                }
            }
        }
    }
}
