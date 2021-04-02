//
//  FileViewController.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import QuickLook
import UIKit

class FileViewController: QLPreviewController {
    var attachments: [MessageComponentExtractor.AttachmentMetaData]
    var loader: AttachmentsLoader

    init(loader: AttachmentsLoader, attachments: [MessageComponentExtractor.AttachmentMetaData]) {
        self.attachments = attachments
        self.loader = loader
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
}

extension FileViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        attachments.count
    }

    func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
        // let cachedItem = loader.loadCachedAttachment(withMetaData: attachments[index])
        // guard cachedItem == nil else {
        //     return cachedItem!
        // }
        return UIImage(named: "DefaultImage")!
    }
}

extension UIImage: QLPreviewItem {
    public var previewItemURL: URL? {
        Bundle.main.url(forResource: "DefaultImage", withExtension: nil)!
    }
}
