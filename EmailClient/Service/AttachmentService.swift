//
//  AttachmentService.swift
//  EmailClient
//
//  Created by SV on 30/03/21.
//

import Foundation

class AttachmentService {
    init(service: GMailAPIService) {
        self.service = service
    }

    private let service: GMailAPIService
}

extension AttachmentService {
    public func fetchAttachmentContents(withId attachmentId: String, withMessageId messageId: String, completionHandler: @escaping (Data?) -> Void) {
        let path: GMailAPIService.Method.Path = .messages(.attachments(messageId: messageId, attachmentId: attachmentId))
        let method: GMailAPIService.Method = .init(pathParameters: path, queryParameters: nil)

        service.executeMethod(method) {
            (messagePartBodyOptional: GMailAPIService.Resource.Message.Part.Body?) in

            guard let messagePartBody = messagePartBodyOptional else {
                completionHandler(nil)
                return
            }

            completionHandler(self.decodeBody(messagePartBody))
        }
    }
}

extension AttachmentService {
    private func decodeBody(_ body: GMailAPIService.Resource.Message.Part.Body) -> Data? {
        guard let decoded = body.data?.fromBase64URL() else {
            return nil
        }
        return decoded.data(using: .utf8)
    }
}
