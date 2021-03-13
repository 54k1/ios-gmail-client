//
//  MessageAttachmentsTableViewCell.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import GoogleAPIClientForREST
import QuickLook
import UIKit

class MessageAttachmentsTableViewCell: UITableViewCell {
    static let identifier = "MessageAttachmentsTableViewCell"
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(AttachmentCollectionViewCell.self, forCellWithReuseIdentifier: AttachmentCollectionViewCell.identifier)
        return collectionView
    }()

    private var attachments: [Attachment]!
    var delegate: ParentTableViewDelegate?
    var previewDelegate: PreviewDelegate?
    var indexPath: IndexPath!
    var messageId: String!
    private var contentsAt = [IndexPath: String]()
    private var pathOf = [IndexPath: URL]()
    private var previewItem: QLPreviewItem!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            collectionView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            collectionView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
    }
}

extension MessageAttachmentsTableViewCell {
    func configure(with attachments: [Attachment]) {
        self.attachments = attachments
        // attachments.forEach({
        //     attachment in
        //     Model.shared.fetchAttachment(withId: attachment.id, completionHandler: {
        //         userMessagePartBody in
        //         let data = userMessagePartBody.data
        //         let decoded = GTLRDecodeWebSafeBase64(data)
        //
        //     })
        // })
        delegate?.setHeight(to: 60, at: indexPath)
        collectionView.reloadData()
    }
}

extension MessageAttachmentsTableViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        attachments?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCollectionViewCell.identifier, for: indexPath) as! AttachmentCollectionViewCell
        let attachment = attachments[indexPath.row]
        Model.shared.fetchAttachment(withId: attachment.id, withMessageId: messageId, completionHandler: {
            userMessagePartBody in
            let decoded = GTLRDecodeWebSafeBase64(userMessagePartBody.data)
            let vc = QLPreviewController()
            vc.dataSource = self
            // let contents = String(data: decoded!, encoding: .utf8)!

            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(attachment.filename)
            try? decoded!.write(to: path)
            self.pathOf[indexPath] = path
        })
        cell.backgroundColor = .systemGreen
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = QLPreviewController()
        vc.dataSource = self
        previewItem = pathOf[indexPath] as! QLPreviewItem
        previewDelegate?.shouldPresent(vc, animated: true)
    }
}

extension MessageAttachmentsTableViewCell: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        1
    }

    func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
        previewItem
    }
}
