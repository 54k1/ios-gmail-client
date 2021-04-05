//
//  AttachmentsView.swift
//  EmailClient
//
//  Created by SV on 31/03/21.
//

import UIKit

class AttachmentsView: UITableViewHeaderFooterView {
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(reuseIdentifier: nil)
        setupCollectionView()
    }

    // MARK: Private

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(AttachmentCollectionViewCell.self, forCellWithReuseIdentifier: AttachmentCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
}

extension AttachmentsView {
    func setCollectionViewDataSource(_ dataSource: UICollectionViewDataSource) {
        collectionView.dataSource = dataSource
    }
}

extension AttachmentsView {
    func setupCollectionView() {
        contentView.addSubview(collectionView)
        collectionView.embed(in: contentView.safeAreaLayoutGuide)

        contentView.backgroundColor = .white
        collectionView.backgroundColor = .white
    }
}
