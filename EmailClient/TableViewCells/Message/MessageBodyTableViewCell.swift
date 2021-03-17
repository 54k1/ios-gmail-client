//
//  MessageBodyTableViewCell.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import UIKit
import WebKit

class MessageBodyTableViewCell: UITableViewCell {
    static let identifier = "MessageBodyTableViewCell"

    private let webView: WKWebView = {
        let view = WKWebView()
        view.scrollView.bounces = false
        return view
    }()

    var delegate: ParentTableViewDelegate?
    var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupWebView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWebView() {
        contentView.addSubview(webView)
        webView.navigationDelegate = self
        Constraints.embed(webView, in: contentView)
    }
}

extension MessageBodyTableViewCell {
    func configure(with htmlString: String) {
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}

extension MessageBodyTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: {
            result, _ in
            if let height = result as? CGFloat {
                self.delegate?.setHeight(to: height, at: self.indexPath!)
            }
        })
    }
}
