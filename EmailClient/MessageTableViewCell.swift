//
//  MessageTableViewCell.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    var message: UserMessage!
    var threadId: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setMessage(_ message: UserMessage) {
        self.message = message
    }

    func setThreadId(_ id: String) {
        threadId = id
    }
}
