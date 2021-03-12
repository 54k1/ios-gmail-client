//
//  MessageHeaderTableViewCell.swift
//  EmailClient
//
//  Created by SV on 09/03/21.
//

import UIKit

class MessageHeaderTableViewCell: UITableViewCell {
    static let identifier = "MessageHeaderTableViewCell"

    private let userLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userLabel)
        contentView.addSubview(dateLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.image = UIImage(systemName: "person")
        userLabel.numberOfLines = 0
        dateLabel.numberOfLines = 0
        userLabel.frame = CGRect(x: 50, y: 0, width: contentView.frame.width - 50, height: contentView.frame.height)
        dateLabel.frame = CGRect(x: 320, y: 0, width: 100, height: contentView.frame.height)
    }

    func configure(with message: UserMessage) {
        userLabel.attributedText = NSAttributedString(string: message.fromName!, attributes: [
            .strokeColor: UIColor.black,
            .font: UIFont.boldSystemFont(ofSize: 20),
        ])
        let dateString = message.headerValueFor(key: "Date")!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let date = formatter.date(from: dateString)!
        if date.distance(to: Date()) > 24 * 60 * 60 {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        dateLabel.text = formatter.string(from: date)
    }
}
