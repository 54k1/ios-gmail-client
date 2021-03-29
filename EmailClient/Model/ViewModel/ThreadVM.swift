//
//  Thread.swift
//  EmailClient
//
//  Created by SV on 28/03/21.
//

import Foundation

extension ViewModel {
    class Thread {
        convenience init(from threadMO: ThreadMO) {
            let messages = threadMO.messages.compactMap {
                Message(from: $0 as! MessageMO)
            } ?? []
            let date = messages.first?.date ?? Date()
            self.init(messages: messages, date: date)
        }

        init(messages: [ViewModel.Message], date: Date) {
            self.messages = messages
            self.date = date
        }

        let messages: [Message]
        let date: Date
    }
}
