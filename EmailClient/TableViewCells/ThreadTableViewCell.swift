//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "ThreadTableViewCell"

    private let activityIndicator = UIActivityIndicatorView()
    private let dateLabel = UILabel()

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ThreadTableViewCell {
    func configure(with threadVM: ViewModel.Thread) {
        detailTextLabel?.text = threadVM.messages.first?.snippet
        textLabel?.text = threadVM.messages.first?.from.name
        imageView?.image = UIImage(systemName: "person.circle")
        if let date = threadVM.messages.first?.date {
            dateLabel.text = dateString(from: date)
        } else {
            dateLabel.text = "<<DateError>>"
        }
    }

    private func dateString(from date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if date.distance(to: Date()) > 24 * 60 * 60 {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }

    func startLoading() {
        activityIndicator.startAnimating()
    }

    private func setupViews() {
        contentView.addSubview(activityIndicator)
        activityIndicator.center(in: contentView)

        contentView.addSubview(dateLabel)
        dateLabel
            .alignTrailing(to: contentView.safeAreaLayoutGuide.trailingAnchor, withPadding: -20.0)
            .alignTop(to: textLabel?.topAnchor ?? contentView.topAnchor)
            .font = detailTextLabel?.font
    }
}
