//
//  AttachmentCollectionViewCell.swift
//  Pods
//
//  Created by SV on 11/03/21.
//

import UIKit
import QuickLook
import GoogleAPIClientForREST

class AttachmentCollectionViewCell: UICollectionViewCell {
    static let identifier = "AttachmentCollectionViewCell"
    
    private let titleView = UILabel()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleView)
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        titleView.numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            // imageView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            titleView.topAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
    }
    
    func configure(with filename: String) {
        imageView.image = UIImage(systemName: "doc.plaintext")
        titleView.text = filename
    }
}
