//
//  AttachmentVM.swift
//  EmailClient
//
//  Created by SV on 30/03/21.
//

import Foundation
import UIKit

extension ViewModel {
    class Attachment {
        convenience init(from attachmentMO: AttachmentMO) {
            self.init(id: attachmentMO.id, messageId: attachmentMO.messageId, filename: attachmentMO.filename, thumbnail: attachmentMO.thumbnail)
        }

        init(id: String, messageId: String, filename: String, thumbnail: Data?) {
            self.id = id
            self.messageId = messageId
            self.filename = filename
            self.thumbnail = thumbnail
        }

        let id: String
        let messageId: String
        let filename: String
        let thumbnail: Data?
    }
}
