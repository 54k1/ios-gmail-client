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
            }
            let date = messages.first?.date ?? Date()
            self.init(id: threadMO.id, messages: messages, date: date)
        }

        init(id: String, messages: [ViewModel.Message], date: Date) {
            self.messages = messages.sorted { (m1, m2) -> Bool in
                m1.date < m2.date
            }
            self.date = date
            self.id = id
        }

        let messages: [Message]
        let date: Date
        let id: String
    }
}
