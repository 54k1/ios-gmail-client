//
//  MessageFooterTableViewCell.swift
//  EmailClient
//
//  Created by SV on 09/03/21.
//

import UIKit

class MessageFooterTableViewCell: UITableViewCell {
    static let identifier = "MessageFooterTableViewCell"
    static var nib: UINib {
        UINib(nibName: Self.identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
