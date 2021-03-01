//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    // MARK: Outlets
    @IBOutlet var snippetLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    
    // MARK: Properties

    var threadId: String!

    var threadDetail: ThreadDetail!
    var snippet: String! {
        didSet {
            self.snippetLabel?.text = snippet
        }
    }
    var from: String! {
        didSet {
            self.fromLabel?.text = from
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    static let identifier = "ThreadTableViewCell"
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override func prepareForReuse() {
        self.snippet = ""
        self.fromLabel.text = ""
    }
}
