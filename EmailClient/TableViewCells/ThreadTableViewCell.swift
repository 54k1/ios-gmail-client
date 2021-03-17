//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "ThreadTableViewCell"

    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with threadDetail: ThreadDetail) {
        detailTextLabel?.text = threadDetail.messages[0].snippet
        textLabel?.text = threadDetail.messages[0].fromName!
        imageView?.image = UIImage(systemName: "person")

        let dateString = threadDetail.messages[0].headerValueFor(key: "Date")!
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

extension ThreadTableViewCell {
    private func setupDateLabel() {
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.bottomAnchor.constraint(equalTo: detailTextLabel!.topAnchor, constant: 5),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
        ])
    }

    private func setupViews() {
        setupDateLabel()
        detailTextLabel?.numberOfLines = 3
    }
}
