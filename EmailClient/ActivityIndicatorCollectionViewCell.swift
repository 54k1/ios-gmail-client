//
//  ActivityIndicatorCollectionViewCell.swift
//  EmailClient
//
//  Created by SV on 23/03/21.
//

import UIKit

class ActivityIndicatorCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ActivityIndicatorCollectionViewCell"

    private let activityIndicator = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func startSpinning() {
        activityIndicator.startAnimating()
    }

    private func setupViews() {
        contentView.addSubview(activityIndicator)
        activityIndicator.center(in: contentView)
    }
}
