//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "ThreadTableViewCell"

    private let senderLabel = UILabel()
    private let snippetLabel = UILabel()
    private let starButton = UIButton()
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
        textLabel?.text = threadDetail.messages[0].snippet
        detailTextLabel?.text = threadDetail.messages[0].fromName!
        imageView!.image = UIImage(systemName: "person")

        let dateString = threadDetail.messages[0].headerValueFor(key: "Date")!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let date = formatter.date(from: dateString)!
        if date.distance(to: Date()) > 24 * 60 * 60 {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        // dateLabel.text = formatter.string(from: date)
    }
}

extension ThreadTableViewCell {
    private func setupViews() {
        setupLabels()
    }

    private func setupLabels() {
        [senderLabel, snippetLabel, dateLabel].forEach {
            contentView.addSubview($0)
        }
//        senderLabel
//            .alignLeading(to: contentView.safeAreaLayoutGuide.leadingAnchor, withPadding: 45.0)
//            .alignTop(to: contentView.safeAreaLayoutGuide.bottomAnchor, withPadding: 5.0)
//
//        snippetLabel.alignTop(to: senderLabel.bottomAnchor, withPadding: 5.0)
//        .alignLeading(to: senderLabel.leadingAnchor)
//            .alignTrailing(to: contentView.safeAreaLayoutGuide.trailingAnchor, withPadding: 10.0)
//
//        dateLabel
//            .alignTop(to: senderLabel.topAnchor)
//            .alignTrailing(to: contentView.safeAreaLayoutGuide.trailingAnchor, withPadding: -20.0)
//        NSLayoutConstraint.activate([
//            dateLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor)
//        ])
    }
}
