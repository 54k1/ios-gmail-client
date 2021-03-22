//
//  FileViewController.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import UIKit
import QuickLook

class FileViewController: QLPreviewController {
    var attachments: [Attachment]
    
    init(attachments: [Attachment]) {
        self.attachments = attachments
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        self.dataSource = self
    }

}

extension FileViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        attachments.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        attachments[index]
    }
}
