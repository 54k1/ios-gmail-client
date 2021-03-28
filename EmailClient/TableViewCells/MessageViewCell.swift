//
//  MessageViewCell.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import QuickLook
import UIKit
import WebKit

private enum Constants {
    static let headerHeight: CGFloat = 50
    static let headerSpacing: CGFloat = 10
    static let attachmentsViewHeight: CGFloat = 150
    static let attachmentHeight: CGFloat = 130
    static let imageSide: CGFloat = 50
    static let personImage = UIImage(systemName: "person.circle")!
}

class MessageViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageViewCell"
    static let loadingCellreuseIdentifier = "loadingCell"

    private let stackView = UIStackView()
    private let headerView = UIStackView()
    private let labelView = UILabel()
    private let dateLabel = UILabel()
    private let webView = WKWebView()
    private let attachmentsView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Constants.attachmentHeight, height: Constants.attachmentHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(AttachmentCollectionViewCell.self, forCellWithReuseIdentifier: AttachmentCollectionViewCell.reuseIdentifier)
        collectionView.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: ActivityIndicatorCollectionViewCell.reuseIdentifier)
        return collectionView
    }()

    var delegate: CollectionViewDelegate?
    public private(set) var height: CGFloat = 0.0

    private var attachmentsMetaData = [MessageComponentExtractor.AttachmentMetaData]()
    private var hasAttachments: Bool {
        attachmentsMetaData.count > 0
    }

    var attachmentsLoader: AttachmentsLoader?

    private var messageId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MessageViewCell {
    private func setupViews() {
        stackView.axis = .vertical
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self

        stackView.addArrangedSubview(headerView)
        setupAttachmentsView()
        stackView.addArrangedSubview(webView)
        contentView.addSubview(stackView)
        setupHeaderView()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.embed(in: contentView.layoutMarginsGuide)
    }

    private func setupHeaderView() {
        // Sender Image
        func setupImageView() {
            let imageView = UIImageView(image: Constants.personImage)
            imageView
                .setConstant(height: Constants.imageSide)
                .setConstant(width: Constants.imageSide)

            headerView.addArrangedSubview(imageView)
        }

        // SenderName Label
        func setupLabelView() {
            labelView.font = .systemFont(ofSize: 20, weight: .regular)
            headerView.addArrangedSubview(labelView)
        }

        headerView.setConstant(height: Constants.headerHeight)
        headerView.spacing = Constants.headerSpacing

        setupImageView()
        setupLabelView()
        headerView.addArrangedSubview(dateLabel)
    }

    private func setupAttachmentsView() {
        (collectionView.dataSource, collectionView.delegate) = (self, self)

        attachmentsView.addArrangedSubview(collectionView)

        attachmentsView.setConstant(height: Constants.attachmentsViewHeight)
        attachmentsView.backgroundColor = .white
        collectionView.backgroundColor = .white
    }
}

extension MessageViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: {
            result, _ in
            if let height = result as? CGFloat {
                self.height = height + Constants.headerHeight + (self.hasAttachments ? Constants.attachmentsViewHeight : 0) + 30
            }
        })
    }
}

extension MessageViewCell {
    private func prepareToLoadAttachments() {
        stackView.insertArrangedSubview(attachmentsView, at: 1)
        collectionView.reloadData()
    }

    func configure(with result: MessageComponentExtractor.MessageResult) {
        guard case let .success(extractedMessage) = result else {
            // Show Error
            return
        }
        webView.loadHTMLString(extractedMessage.html, baseURL: nil)
        labelView.text = extractedMessage.from?.name
        dateLabel.text = extractedMessage.dateString
        attachmentsMetaData = extractedMessage.attachments
        if attachmentsMetaData.count > 0 {
            prepareToLoadAttachments()
        }
    }

    func configure(with messageVM: ViewModel.Message) {
        webView.loadHTMLString(messageVM.html, baseURL: nil)
        labelView.text = messageVM.from.name
        dateLabel.text = messageVM.dateString
    }
}

extension MessageViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        attachmentsMetaData.removeAll()
        stackView.removeArrangedSubview(attachmentsView)
    }
}

extension MessageViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        attachmentsMetaData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCollectionViewCell.reuseIdentifier, for: indexPath) as? AttachmentCollectionViewCell else {
            fatalError("\(AttachmentCollectionViewCell.reuseIdentifier) has not been registered or internal error")
        }
        let attachmentMetaData = attachmentsMetaData[indexPath.row]
        guard let attachment = attachmentsLoader?.loadCachedAttachment(withMetaData: attachmentMetaData) else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivityIndicatorCollectionViewCell.reuseIdentifier, for: indexPath) as? ActivityIndicatorCollectionViewCell else {
                fatalError("\(ActivityIndicatorCollectionViewCell.reuseIdentifier) has not been registered or internal error")
            }
            cell.startSpinning()
            return cell
        }
        if let image = attachment.thumbnail {
            cell.configure(withImage: image)
        } else {
            cell.configure(withImage: UIImage(systemName: "doc.fill")!)
        }
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItemAt(indexPath, attachmentsMetaData: attachmentsMetaData)
    }
}

protocol CollectionViewDelegate {
    func didSelectItemAt(_ indexPath: IndexPath, attachmentsMetaData: [MessageComponentExtractor.AttachmentMetaData]?)
}
