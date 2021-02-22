//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    // MARK: Outlets
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var snippetLabel: UILabel!
    
    // MARK: Properties
    var threadId: String!
    var snippet: String! {
        didSet {
            self.snippetLabel?.text = snippet
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
    
    func setThreadId(_ id: String) {
        threadId = id
    }

    func setSnippet(_ snippet: String) {
        self.snippet = snippet
    }
    
    
    static let identifier = "ThreadTableViewCell"
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }

    @IBAction func toggleStar(_ sender: UIButton) {
        let image = UIImage(systemName: "star.fill")!
        sender.setImage(image, for: .normal)
    }
}
