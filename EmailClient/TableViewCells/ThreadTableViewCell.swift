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
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            dateLabel.centerYAnchor.constraint(equalTo: userLabel.centerYAnchor),
        ])
        NSLayoutConstraint.activate([
            userLabel.leadingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 10),
            userLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            // userLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -10),
            userLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
        ])
        NSLayoutConstraint.activate([
            snippetLabel.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 10),
            snippetLabel.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            snippetLabel.leadingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 10),
            snippetLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
        ])
        activiyIndicator.frame = contentView.bounds
        imageView?.image = UIImage(systemName: "person")!
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
