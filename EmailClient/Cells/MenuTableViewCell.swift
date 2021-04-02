//
//  MenuTableViewCell.swift
//  EmailClient
//
//  Created by SV on 15/03/21.
//

import UIKit

class MenuTableViewCell: UITableViewCell {
    static let identifier = "MenuTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(withLabelText labelText: String, withImage image: UIImage? = nil) {
        imageView?.image = image
        imageView?.contentMode = .scaleAspectFit
        textLabel?.text = labelText
    }
}
