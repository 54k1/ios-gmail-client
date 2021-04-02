//
//  Attachment.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation

class Attachment {
    init(withName name: String, withLocation location: URL) {
        self.name = name
        self.location = location
    }

    private let name: String
    private let location: URL
}
