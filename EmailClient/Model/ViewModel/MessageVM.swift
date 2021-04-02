//
//  MessageVM.swift
//  EmailClient
//
//  Created by SV on 28/03/21.
//

import Foundation

extension ViewModel {
    class Message {
        convenience init(from messageMO: MessageMO) {
            let html = messageMO.html
            let date = messageMO.internalDate
            let subject = messageMO.subject
            let snippet = messageMO.snippet
            let fromName = messageMO.fromName
            let fromEmail = messageMO.fromEmail
            let id = messageMO.id
            let attachments = messageMO.attachments?.compactMap {
                Attachment(from: $0 as! AttachmentMO)
            } ?? []
            let from = (name: fromName, email: fromEmail)
            self.init(id: id, snippet: snippet, subject: subject, date: date, from: from, html: html, attachments: attachments)
        }

        init(id: String, snippet: String, subject: String, date: Date, from: (name: String?, email: String), html: String, attachments: [ViewModel.Attachment]) {
            self.id = id
            self.snippet = snippet
            self.subject = subject
            self.date = date
            self.from = from
            self.html = html
            self.attachments = attachments
        }

        let id: String
        let snippet: String
        let subject: String
        let date: Date
        let from: (name: String?, email: String)
        let html: String
        let attachments: [Attachment]
    }
}
