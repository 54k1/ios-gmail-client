//
//  AttachmentsLoader.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation
import QuickLook
import UIKit

class AttachmentsLoader: NSObject {
    typealias AttachmentCallback = (Attachment?) -> Void
    private let service: AttachmentService
    private var attachmentsCache = [String: Attachment]()
    private let queue = DispatchQueue.global()

    init(service: AttachmentService) {
        self.service = service
    }
}

extension AttachmentsLoader {
    public func downloadAttachment(withId attachmentId: String, withMessageId messageId: String, completionHandler: @escaping (URL?) -> Void) {
        service.fetchAttachmentContents(withId: attachmentId, withMessageId: messageId, completionHandler: {
            dataOptional in
            guard let data = dataOptional else {
                completionHandler(nil)
                return
            }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(attachmentId + messageId)
            do {
                try data.write(to: url)
                completionHandler(url)
            } catch {
                completionHandler(nil)
            }
        })
    }

    func generatePreviewThumbnail(forFileAt url: URL, callback: @escaping (UIImage?) -> Void) {
        let size = CGSize(width: 300, height: 300)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 0.7, representationTypes: .all)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) {
            rep, err in
            guard err == nil, let rep = rep else {
                callback(nil)
                return
            }
            callback(rep.uiImage)
        }
    }
}
