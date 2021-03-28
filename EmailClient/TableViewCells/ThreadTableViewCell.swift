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
    func configure(with thread: GMailAPIService.Resource.Thread) {
        activityIndicator.stopAnimating()
        textLabel?.text = thread.messages?[0].fromName
        detailTextLabel?.text = thread.messages?[0].snippet
        imageView?.image = UIImage(systemName: "person.circle")
        dateLabel.text = thread.messages?[0].dateString
    }

    func configure(with threadVM: ViewModel.Thread) {
        detailTextLabel?.text = threadVM.messages.first?.snippet
        textLabel?.text = threadVM.messages.first?.from.name
        imageView?.image = UIImage(systemName: "person.circle")
        dateLabel.text = threadVM.messages.first?.dateString
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
