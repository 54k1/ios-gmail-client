//
//  ThreadViewController.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import WebKit

class ThreadDetailViewController: UIViewController {
    // MARK: Properties
    var threadId: String!
    // var messageStackView: UIStackView {
    //     let view = UIStackView()
    //     let scrollView = view.
    // }

    // MARK: Outlets
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Model.shared.fetchThreadDetail(withId: threadId, completionHandler: {
            threadDetail in
            DispatchQueue.main.async {
                self.render(threadDetail)
            }
        })
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}

// MARK: Render
private extension ThreadDetailViewController {
    func render(_ threadDetail: ThreadDetail) {
        threadDetail.messages.forEach {
            message in
            self.render(message)
            // TODO: Horizontal line after each message
        }
    }

    func render(_ message: UserMessage) {
        guard case let .success(component) = extract(message.payload!) else {
            // TODO: Render error popup
            print("failure")
            return
        }

        var alternative: Alternative!
        var attachments = [Attachment]()
        var htmlContent: Content!
        if let mixed = component as? Mixed {
            alternative = mixed.alternative
            attachments = mixed.attachments
        } else if let alt = component as? Alternative {
            alternative = alt
        } else if let content = component as? Content {
            htmlContent = content
        } else {
            NSLog("Cant interpret mime")
            return
        }

        if htmlContent == nil {
            guard let content = alternative.contents.first(where: {
                content in
                content.mimeType == "text/html"
            }) else {
                // Expect htmlContent to be present
                print("no html")
                return
            }
            htmlContent = content
        }

        print("html=", htmlContent.data)
        webView.loadHTMLString(htmlContent.data, baseURL: nil)
        webView.frame.size = webView.scrollView.contentSize
        webView.scrollView.bounces = false
    }
}
