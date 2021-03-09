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
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    // MARK: Properties

    var threadId: String!

    var threadDetail: ThreadDetail!
    var snippet: String! {
        didSet {
            snippetLabel?.text = snippet
        }
    }

    var date: String! {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            formatter.dateStyle = .short
            let dat = formatter.date(from: date)
            let requestedComponents: Set<Calendar.Component> = [
                .day,
                .hour,
                .minute,
            ]
            let calendar = Calendar.current
            // let dateComponents = calendar.dateComponents(requestedComponents, from: dat!)
            // dateLabel?.text = date
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
        snippet = ""
        fromLabel.text = ""
    }
}
