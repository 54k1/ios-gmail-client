//
//  ThreadTableViewCell.swift
//  EmailClient
//
//  Created by SV on 22/02/21.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "ThreadTableViewCell"

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var activityIndicator: UIActivityIndicatorView!
    private var dateLabel: UILabel!
}

// MARK: ViewSetup

extension ThreadTableViewCell {
    private func setupViews() {
        setupActivityIndicator()
        setupDateLabel()
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView()
        contentView.addSubview(activityIndicator)
        activityIndicator.center(in: contentView)
    }

    private func setupDateLabel() {
        dateLabel = UILabel()
        contentView.addSubview(dateLabel)
        dateLabel
            .alignTrailing(to: contentView.safeAreaLayoutGuide.trailingAnchor, withPadding: -20.0)
            .alignTop(to: textLabel?.topAnchor ?? contentView.topAnchor)
            .font = detailTextLabel?.font
    }
}

// MARK: DateFormatter

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
    return formatter
}()

// MARK: Configure

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
        if date.distance(to: Date()) > 24 * 60 * 60 {
            dateFormatter.dateFormat = "dd MMM"
        } else {
            dateFormatter.dateFormat = "HH:mm"
        }
        return dateFormatter.string(from: date)
    }
}

// MARK: Loader

extension ThreadTableViewCell {
    func startLoading() {
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        activityIndicator.stopAnimating()
    }
}
