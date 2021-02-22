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

    // MARK: Outlets

    @IBOutlet var subjectLabel: UILabel!
//    @IBOutlet var fromLabel: UILabel!
//    @IBOutlet var toLabel: UILabel!
//    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        enum MessageDetail {
            case mixed([MessageDetail])
            case alternative([MessageDetail])
            case attachment(mimeType: String, id: String)
            case content(mimeType: String, body: String)
        }

        func extractPartDetail(_ part: UserMessagePart) -> MessageDetail {
            if part.mimeType == "multipart/mixed" {
                var mixed = [MessageDetail]()
                for part in part.parts! {
                    mixed.append(extractPartDetail(part))
                }
                return .mixed(mixed)
            } else if part.mimeType == "multipart/alternative" {
                var alternatives = [MessageDetail]()
                for part in part.parts! {
                    alternatives.append(extractPartDetail(part))
                }
                return .alternative(alternatives)
            } else {
                print("part=", part)
                if let attachmentId = part.body!.attachmentId {
                    return .attachment(mimeType: part.mimeType, id: attachmentId)
                } else {
                    return .content(mimeType: part.mimeType, body: part.body!.data!)
                }
            }
        }

        // Do any additional setup after loading the view.
        Model.shared.fetchMessages(withThreadId: threadId) {
            messages in
            for message in messages {
                if let payload = message.payload {
                    for header in payload.headers {
                        if header.name == "Subject" {
                            let bold: UIFont = .boldSystemFont(ofSize: 30)
                            self.subjectLabel.text = header.value
                            self.subjectLabel.font = bold
                        }
                        if header.name == "From" {
//                            self.fromLabel.text = header.value
                        }
                        if header.name == "Date" {
//                            self.dateLabel.text = header.value
                        }
                        print(header)
                    }
                    let details = extractPartDetail(payload)
                    print(details)
                    func extractDetails(_ details: MessageDetail, _ alternative: Bool = false) {
                        switch details {
                        case let .alternative(alternatives):
                            for alternative in alternatives {
                                extractDetails(alternative, true)
                            }
                        case let .mixed(mixed):
                            for part in mixed {
                                extractDetails(part)
                            }
                        case let .content(mimeType, body):
                            // if alternative {
                            // contnet presnset when alternative absent, so set content.body to be html
                                if mimeType == "text/html" {
                                    let data = GTLRDecodeWebSafeBase64(body)!
                                    let html = String(data: data, encoding: .utf8)!
                                    self.webView.loadHTMLString(html, baseURL: nil)
                                    self.webView.isHidden = false
                                    // self.textView.isHidden = true
                                } else if mimeType == "text/plain" {
                                    // self.webView.isHidden = true
                                    let data = GTLRDecodeWebSafeBase64(body)!
                                    let text = String(data: data, encoding: .utf8)!
                                    print("text=\(text)")
                                    self.webView.loadHTMLString(text, baseURL: nil)
                                }
                            // } else {
                                
                            // }
                        case let .attachment(mimeType, id):
                            print("Found an attachment with id:", id)
                        }
                    }
                    extractDetails(details)
                    // if let parts = payload.parts {
                    //     for part in parts {
                    //         let data = GTLRDecodeWebSafeBase64(part.body!.data!)!
                    //         let html = String(data: data, encoding: .utf8)!
                    //         self.webView.loadHTMLString(html, baseURL: nil)
                    //     }
                    // }
                }
            }
        }
    }

    func setThreadId(_ id: String!) {
        threadId = id
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for _: UIStoryboardSegue, sender _: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

    // override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    //     super.dismiss(animated: flag, completion: completion)
    //     print("dismissing")
    // }
}
