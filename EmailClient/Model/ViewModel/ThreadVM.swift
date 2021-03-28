//
//  Thread.swift
//  EmailClient
//
//  Created by SV on 28/03/21.
//

import Foundation

extension ViewModel {
    class Thread {
        init(from threadMO: ThreadMO) {
            messages = threadMO.messages?.compactMap {
                Message(from: $0 as! MessageMO)
            } ?? []
            date = Date()
        }

        init(messages: [ViewModel.Message], date: Date) {
            self.messages = messages
            self.date = date
        }

        let messages: [Message]
        let date: Date
    }
}
