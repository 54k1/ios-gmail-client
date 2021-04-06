//
//  MessageBuilder.swift
//  EmailClient
//
//  Created by SV on 06/04/21.
//

import Foundation
import MessageUI

final class MessageBuilder {
    private var components: (to: String?, subject: String?, contents: String?) = (nil, nil, nil)

    func to(_ email: String) -> Self {
        components.to = email
        return self
    }

    func subject(_ subject: String) -> Self {
        components.subject = subject
        return self
    }

    func contents(_ contents: String) -> Self {
        components.contents = contents
        return self
    }

    func rawMessage() -> String? {
        guard let to = components.to, let subject = components.subject, let contents = components.contents else {
            return nil
        }
        let rfc = """
        Date: \(Date().toRFCDateString())
        Subject: \(subject)
        To: \(to)
        Content-Type: text/html; charset="UTF-8"\r\n\r\n
        <div dir="ltr">\(contents)</div>
        """

        return rfc.toBase64URL()
    }
}

extension DateFormatter {
    static var rfcDateFormat: String {
        "EEE, dd MMM yyyy HH:mm:ss Z"
    }
}

extension Date {
    func toRFCDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.rfcDateFormat
        return formatter.string(from: self)
    }
}

private func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.rfcDateFormat
    return formatter.string(from: date)
}
