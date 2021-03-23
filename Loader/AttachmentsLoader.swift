//
//  AttachmentsLoader.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation
import UIKit

class AttachmentsLoader: NSObject {
    typealias AttachmentCallback = (Attachment?) -> Void
    private let service: CachedGmailAPIService
    private var attachmentsCache = [String: Attachment]()

    init(service: CachedGmailAPIService) {
        self.service = service
    }
}

extension AttachmentsLoader {
    func loadCachedAttachment(withMetaData attachmentMetaData: MessageComponentExtractor.AttachmentMetaData) -> Attachment? {
        let key = attachmentMetaData.messageId + attachmentMetaData.id
        return attachmentsCache[key]
    }

    func loadAttachment(withMetaData attachmentMetaData: MessageComponentExtractor.AttachmentMetaData, completionHandler: @escaping AttachmentCallback) {
        let key = attachmentMetaData.messageId + attachmentMetaData.id
        let cachedItem = attachmentsCache[key]

        guard cachedItem == nil else {
            completionHandler(cachedItem)
            return
        }

        service.getAttachment(withMetaData: attachmentMetaData, completionHandler: {
            attachment in
            guard let attachment = attachment else {
                completionHandler(nil)
                return
            }
            attachment.generateThumbnail(completionHandler: { _ in
                self.attachmentsCache[key] = attachment
                completionHandler(attachment)
            })
        })
    }

    func loadAttachments(_ attachments: [MessageComponentExtractor.AttachmentMetaData], forMessageWithId messageId: String, completionHandler: @escaping ([Attachment]?) -> Void) {
        service.get(attachments, forMessageId: messageId, completionHandler: {
            attachments in
            guard let attachments = attachments else {
                completionHandler(nil)
                return
            }
            completionHandler(attachments)
        })
    }
}
