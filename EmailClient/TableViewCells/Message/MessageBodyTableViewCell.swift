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

    private let webView: WKWebView

    var delegate: ParentTableViewDelegate?
    var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        webView = WKWebView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        contentView.addSubview(webView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = contentView.bounds
    }
}

extension MessageBodyTableViewCell {
    func configure(with htmlString: String) {
        print("configure:\(Self.description())")
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}

extension MessageBodyTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        print("didFinish")
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: {
            result, _ in
            if let height = result as? CGFloat {
                self.delegate?.setHeight(to: height, at: self.indexPath!)
            }
        })
    }
}
