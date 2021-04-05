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
    static let identifier = "AttachmentCollectionViewCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var imageView: UIImageView!
    private var activityIndicator: UIActivityIndicatorView!
}

// MARK: ViewSetup

extension AttachmentCollectionViewCell {
    private func setupImageView() {
        imageView = UIImageView()
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        imageView.layer.borderWidth = 1
        imageView.embed(in: contentView.safeAreaLayoutGuide)
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView()
        contentView.addSubview(activityIndicator)
        activityIndicator.isHidden = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        activityIndicator.center(in: contentView)
    }

    private func setupViews() {
        setupImageView()
        setupActivityIndicator()
        imageView.isHidden = true
    }
}

// MARK: Configure

extension AttachmentCollectionViewCell {
    func configure(with attachmentVM: ViewModel.Attachment) {
        if let data = attachmentVM.thumbnail {
            imageView.isHidden = false
            imageView.image = UIImage(data: data)

            activityIndicator.stopAnimating()
        }
    }
}

extension AttachmentCollectionViewCell: ReuseableCell {
    static var reuseIdentifier: String {
        Self.identifier
    }
}
