//
//  AttachmentCollectionViewCell.swift
//  Pods
//
//  Created by SV on 11/03/21.
//

import GoogleAPIClientForREST
import QuickLook
import UIKit

class AttachmentCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "AttachmentCollectionViewCell"

    private let titleView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        imageView.layer.borderWidth = 1
        return imageView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.isHidden = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        return activityIndicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleView)
        contentView.addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.embed(in: contentView.safeAreaLayoutGuide)
    }

    func configure(withName filename: String) {
        titleView.text = filename
    }

    func configure(withImage image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
    }
}
