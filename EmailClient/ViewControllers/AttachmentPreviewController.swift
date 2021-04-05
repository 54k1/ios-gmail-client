//
//  AttachmentPreviewController.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import QuickLook
import UIKit

class AttachmentPreviewController: QLPreviewController {
    init(message: MessageMO) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        dataSource = self
    }

    let message: MessageMO
}

extension AttachmentPreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        message.attachments?.count ?? 0
    }

    func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = NSURL(string: (message.attachments!.allObjects[index] as! AttachmentMO).location!)!
        return url
    }
}

extension UIImage: QLPreviewItem {
    public var previewItemURL: URL? {
        Bundle.main.url(forResource: "DefaultImage", withExtension: nil)!
    }
}
