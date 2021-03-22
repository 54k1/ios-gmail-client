//
//  AttachmentsLoader.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation

class AttachmentsLoader: NSObject {
    private let service: CachedGmailAPIService
    private var attachmentsCache = [String: Attachment]()
    
    init(service: CachedGmailAPIService) {
        self.service = service
    }
}

extension AttachmentsLoader {
    func loadAttachments(_ attachments: [MessageComponentExtractor.Attachment], forMessageWithId messageId: String, completionHandler: @escaping ([Attachment]?) -> Void) {
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
