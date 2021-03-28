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
            let fromName = messageMO.fromName
            let fromEmail = messageMO.fromEmail
            let id = messageMO.id
            self.init(html: html, date: date, subject: subject, snippet: messageMO.snippet, from: (name: fromName, email: fromEmail), id: id)
        }

        init(html: String, date: Date, subject: String, snippet: String, from: (name: String?, email: String), id: String) {
            self.html = html
            self.date = date
            self.subject = subject
            self.snippet = snippet
            self.from = from
            self.id = id
        }

        let html: String
        let date: Date
        let subject: String
        let snippet: String
        let from: (name: String?, email: String)
        let id: String
    }
}
