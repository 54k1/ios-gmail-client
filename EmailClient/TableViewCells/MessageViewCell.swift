//
//  MessageViewCell.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import UIKit
import WebKit
import QuickLook

fileprivate enum Constants {
    static let headerHeight: CGFloat = 50
    static let headerSpacing: CGFloat = 10
    static let attachmentsViewHeight: CGFloat = 150
    static let attachmentHeight: CGFloat = 130
    static let imageSide: CGFloat = 50
}

class MessageViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageViewCell"
    static let loadingCellreuseIdentifier = "loadingCell"

    let stackView = UIStackView()
    let headerView = UIStackView()
    let labelView = UILabel()
    let webView = WKWebView()
    let attachmentsView = UIStackView()
    let activityIndicator = UIActivityIndicatorView()
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Constants.attachmentHeight, height: Constants.attachmentHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(AttachmentCollectionViewCell.self, forCellWithReuseIdentifier: AttachmentCollectionViewCell.reuseIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: loadingCellreuseIdentifier)
        return collectionView
    } ()
    
    var delegate: CollectionViewDelegate?
    var height: CGFloat = 0.0
    var hasAttachments = false
    var attachmentCount = 0
    var attachments: [Attachment]?

    var messageId: String?

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
            let imageView = UIImageView(image: UIImage(systemName: "person.circle")!)
            imageView
                .setConstant(height: Constants.imageSide)
                .setConstant(width: Constants.imageSide)

            headerView.addArrangedSubview(imageView)
        }

        // SenderName Label
        func setupLabelView() {
            labelView.font = .systemFont(ofSize: 20, weight: .medium)
            headerView.addArrangedSubview(labelView)
        }
        
        headerView.setConstant(height: Constants.headerHeight)
        headerView.spacing = Constants.headerSpacing
        
        setupImageView()
        setupLabelView()
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
    private func prepareToLoadAttachments(_ count: Int) {
        hasAttachments = true
        self.attachmentCount = count
        stackView.insertArrangedSubview(attachmentsView, at: 1)
        collectionView.reloadData()
    }

    func configure(from: String) {
        labelView.text = from
    }
    
    func configure(withHTML html: String, attachmentCount: Int) {
        webView.loadHTMLString(html, baseURL: nil)
        guard attachmentCount > 0 else {return}
        prepareToLoadAttachments(attachmentCount)
    }
    
    func set(attachments: [Attachment]) {
        self.attachments = attachments
    }
}

extension MessageViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        attachmentCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard attachments != nil else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.loadingCellreuseIdentifier, for: indexPath)
            let activityIndicator = UIActivityIndicatorView()
            cell.addSubview(activityIndicator)
            activityIndicator.center(in: cell)
            activityIndicator.startAnimating()
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCollectionViewCell.reuseIdentifier, for: indexPath) as? AttachmentCollectionViewCell else {
            fatalError("Could not dequee AttachmentCollectionViewCell")
        }
        guard let attachment = attachments?[indexPath.row] else {
            fatalError("Requested unknown attachment")
        }
        if let image = attachment.thumbnail {
            cell.configure(withImage: image)
        } else {
            cell.configure(withImage: UIImage(systemName: "doc.fill")!)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItemAt(indexPath, attachments: self.attachments)
    }
}

protocol CollectionViewDelegate {
    func didSelectItemAt(_ indexPath: IndexPath, attachments: [Attachment]?)
}

/// Extracting necessary information from Message
extension GMailAPIService.Resource.Message {
    func headerValueFor(key: String) -> String? {
        if let payload = self.payload {
            for header in payload.headers {
                if header.name == key {
                    return header.value
                }
            }
        }
        return nil
    }

    var fromName: String? {
        guard let from = headerValueFor(key: "From") else {
            return nil
        }
        return Self.extractName(from)
    }

    var fromEmail: String? {
        guard let from = headerValueFor(key: "From") else {
            return nil
        }
        return Self.extractEmail(from)
    }

    private static func extractName(_ string: String) -> String {
        if let index = string.firstIndex(of: "<") {
            return String(string.prefix(upTo: index))
        }
        return string
    }

    private static func extractEmail(_ string: String) -> String {
        if let index = string.firstIndex(of: "<") {
            return String(string.suffix(from: index))
        }
        return string
    }

    var toName: String? {
        guard let to = headerValueFor(key: "To") else {
            return nil
        }
        return Self.extractName(to)
    }

    var toEmail: String? {
        guard let to = headerValueFor(key: "To") else {
            return nil
        }
        return Self.extractEmail(to)
    }
}
