//
//  Constraints.swift
//  EmailClient
//
//  Created by SV on 16/03/21.
//

import UIKit

class Constraints {
    /// represents the edge to which view is pinned to
    enum Edge {
        enum Vertical {
            case top, bottom
        }

        enum Horizontal {
            case leading, trailing
        }

        case vertical(Vertical)
        case horizontal(Horizontal)
    }

    /// embed in safeArea of outerView
    static func embed(_ innerView: UIView, in outerView: UIView, with padding: CGFloat = 0.0) {
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.topAnchor, constant: padding),
            innerView.bottomAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            innerView.leadingAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            innerView.trailingAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
        ])
    }

    /// center in safeArea of outerView
    static func center(_ innerView: UIView, in outerView: UIView) {
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.centerXAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.centerXAnchor),
            innerView.centerYAnchor.constraint(equalTo: outerView.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    static func pin(_ view: UIView, to: NSLayoutYAxisAnchor, on edge: Edge, padding: CGFloat = 0.0) {
        guard case let .vertical(edge) = edge else {
            fatalError("Illegal constraint")
        }
        switch edge {
        case .top:
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: to, constant: padding),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                view.bottomAnchor.constraint(equalTo: to, constant: padding),
            ])
        }
    }

    static func pin(_ view: UIView, to: NSLayoutXAxisAnchor, on edge: Edge, padding: CGFloat = 0.0) {
        guard case let .horizontal(edge) = edge else {
            fatalError("Illegal constraint")
        }
        switch edge {
        case .leading:
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: to, constant: padding),
            ])
        case .trailing:
            NSLayoutConstraint.activate([
                view.trailingAnchor.constraint(equalTo: to, constant: padding),
            ])
        }
    }
}
