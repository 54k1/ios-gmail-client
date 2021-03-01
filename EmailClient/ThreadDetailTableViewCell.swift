//
//  ThreadDetailTableViewCell.swift
//  EmailClient
//
//  Created by SV on 28/02/21.
//

import UIKit
import WebKit

class ThreadDetailTableViewCell: UITableViewCell {
    static let identifier = "ThreadDetailTableViewCell"
    static let nibName = UINib(nibName: "ThreadDetailTableViewCell", bundle: nil)

    // MARK: Outlets
    @IBOutlet var webView: WKWebView!
    
    // MARK: Properties
    var html: String!
    var delegate: ThreadDetailTableViewCellDelegate!
    var indexPath: IndexPath!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        webView.navigationDelegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

protocol ThreadDetailTableViewCellDelegate {
    func didCalculateHeightFor(_ cell: ThreadDetailTableViewCell, height: CGFloat)
}

extension ThreadDetailTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // delegate.webView?(webView, didFinish: navigation)
        // delegate.webView(webView, didFinish: navigation)
         let javascript = """
             var meta = document.createElement('meta');
             meta.setAttribute('name', 'viewport');
             meta.setAttribute('content', 'width=device-width, intial-scale=auto');
             document.getElementsByTagName('head')[0].appendChild(meta);
             """

         webView.evaluateJavaScript(javascript, completionHandler: nil)
        
         let documentHeight = "document.body.scrollHeight"
         webView.evaluateJavaScript(documentHeight, completionHandler: {
             result, error in
             if let height = result as? CGFloat {
                self.delegate.didCalculateHeightFor(self, height: height)
            }
        })
        
    }
}
