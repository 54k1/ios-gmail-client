//
//  MessageHeaderTableViewCell.swift
//  EmailClient
//
//  Created by SV on 09/03/21.
//

import UIKit

class MessageHeaderTableViewCell: UITableViewCell {
    static let identifier = "MessageHeaderTableViewCell"
    static var nib: UINib {
        return UINib(nibName: Self.identifier, bundle: nil)
    }

    // MARK: Outlets

    @IBOutlet var usernameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
