//
//  Constraints.swift
//  EmailClient
//
//  Created by SV on 16/03/21.
//

import UIKit

class Constraints {
    static func embed(_ innerView: UIView, in outerView: UIView, with padding: CGFloat = 0.0) {
        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: outerView.topAnchor, constant: padding),
            innerView.bottomAnchor.constraint(equalTo: outerView.bottomAnchor, constant: -padding),
            innerView.leadingAnchor.constraint(equalTo: outerView.leadingAnchor, constant: padding),
            innerView.trailingAnchor.constraint(equalTo: outerView.trailingAnchor, constant: -padding),
        ])
    }
}
