//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "ThreadTableViewCell"

    private let userLabel = UILabel()
    private let snippetLabel = UILabel()
    private let dateLabel = UILabel()
    private let activiyIndicator = UIActivityIndicatorView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userLabel)
        contentView.addSubview(snippetLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(activiyIndicator)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        userLabel.frame = CGRect(x: 60, y: 5, width: contentView.frame.width - 20, height: contentView.frame.height / 3)
        snippetLabel.frame = CGRect(x: 60, y: 30, width: contentView.frame.width - 60, height: 2 * contentView.frame.height / 3)
        dateLabel.frame = CGRect(x: 340, y: 5, width: contentView.frame.width - 60, height: contentView.frame.height / 3)
        activiyIndicator.frame = contentView.bounds
        imageView?.image = UIImage(systemName: "person")!
        userLabel.numberOfLines = 0
        snippetLabel.numberOfLines = 0
    }

    func configure(with threadId: String) {
        activiyIndicator.startAnimating()
        Model.shared.fetchThreadDetail(withId: threadId, completionHandler: {
            threadDetail in
            self.activiyIndicator.stopAnimating()
            let attributes: [NSAttributedString.Key: Any] = [
                .strokeColor: UIColor.black,
                .font: UIFont.boldSystemFont(ofSize: 20),
            ]
            self.userLabel.attributedText = NSAttributedString(string: threadDetail.messages[0].fromName!, attributes: attributes)
            self.snippetLabel.text = threadDetail.messages[0].snippet
            let dateString = threadDetail.messages[0].headerValueFor(key: "Date")!
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            let date = formatter.date(from: dateString)!
            if date.distance(to: Date()) > 24 * 60 * 60 {
                formatter.dateFormat = "dd MMM"
            } else {
                formatter.dateFormat = "HH:mm"
            }
            self.dateLabel.text = formatter.string(from: date)
        })
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activiyIndicator.startAnimating()
    }
}
