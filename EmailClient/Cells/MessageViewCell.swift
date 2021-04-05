//
//  MessageViewCell.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import CoreData
import QuickLook
import UIKit
import WebKit

class MessageViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private let stackView = UIStackView()
    private let headerView = UIStackView()
    private let labelView = UILabel()
    private let dateLabel = UILabel()
    private let webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView()

    private(set) var height: CGFloat = 0.0
    private(set) var messageVM: ViewModel.Message?
}

// MARK: Constants

private enum Constants {
    static let headerHeight: CGFloat = 50
    static let headerSpacing: CGFloat = 10
    static let attachmentsViewHeight: CGFloat = 150
    static let attachmentHeight: CGFloat = 130
    static let imageSide: CGFloat = 50
    static let personImage = UIImage(systemName: "person.circle")!
}

// MARK: ViewSetup

extension MessageViewCell {
    private func setupViews() {
        stackView.axis = .vertical
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self

        stackView.addArrangedSubview(headerView)
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
}

// MARK: WebViewNavigationDelegate

extension MessageViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: {
            result, _ in
            if let height = result as? CGFloat {
                self.height = height + Constants.headerHeight + 30
            }
        })
    }
}

extension MessageViewCell {
    func configure(with messageVM: ViewModel.Message) {
        self.messageVM = messageVM
        webView.loadHTMLString(messageVM.html, baseURL: nil)
        labelView.text = messageVM.from.name
        dateLabel.text = dateString(from: messageVM.date)
    }

    private func dateString(from date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if date.distance(to: Date()) > 24 * 60 * 60 {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }
}

extension MessageViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        messageVM = nil
    }
}

protocol CollectionViewDelegate {
    func didSelectItemAt(_ indexPath: IndexPath, attachmentsMetaData: [MessageComponentExtractor.AttachmentMetaData]?)
}
