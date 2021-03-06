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

extension UIView {
    func center(in superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
    }
}

extension UIView {
    func embed(in layoutGuide: UILayoutGuide, withPadding padding: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        applyConstraints([
            topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -padding),
            leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding),
        ])
    }

    func embed(inSafeAreaOf superView: UIView, withPadding padding: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        embed(in: superView.safeAreaLayoutGuide, withPadding: padding)
    }
}

extension UIView {
    @discardableResult
    func alignTop(to anchor: NSLayoutYAxisAnchor, withPadding padding: CGFloat = 0) -> Self {
        applyConstraint(topAnchor.constraint(equalTo: anchor, constant: padding))
    }

    @discardableResult
    func alignTrailing(to anchor: NSLayoutXAxisAnchor, withPadding padding: CGFloat = 0) -> Self {
        applyConstraint(trailingAnchor.constraint(equalTo: anchor, constant: padding))
    }

    @discardableResult
    func alignLeading(to anchor: NSLayoutXAxisAnchor, withPadding padding: CGFloat = 0) -> Self {
        applyConstraint(leadingAnchor.constraint(equalTo: anchor, constant: padding))
    }
}

extension UIView {
    @discardableResult
    func applyConstraint(_ constraint: NSLayoutConstraint) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        constraint.isActive = true

        return self
    }

    @discardableResult
    func applyConstraints(_ constraints: [NSLayoutConstraint]) -> Self {
        for constraint in constraints {
            applyConstraint(constraint)
        }
        return self
    }
}

extension UIView {
    @discardableResult
    func setConstant(width: CGFloat) -> Self {
        applyConstraint(widthAnchor.constraint(equalToConstant: width))
    }

    @discardableResult
    func setConstant(height: CGFloat) -> Self {
        applyConstraint(heightAnchor.constraint(equalToConstant: height))
    }
}

extension UIView {
    @discardableResult
    func set(widthTo anchor: NSLayoutDimension) -> Self {
        applyConstraint(widthAnchor.constraint(equalTo: anchor))
    }

    @discardableResult
    func set(heightTo anchor: NSLayoutDimension) -> Self {
        applyConstraint(heightAnchor.constraint(equalTo: anchor))
    }
}

extension UIView {
    @discardableResult
    func alignCenterY(to anchor: NSLayoutYAxisAnchor, withPadding padding: CGFloat = 0) -> Self {
        applyConstraint(centerYAnchor.constraint(equalTo: anchor, constant: padding))
    }

    @discardableResult
    func alignCenterX(to anchor: NSLayoutXAxisAnchor, withPadding padding: CGFloat = 0) -> Self {
        applyConstraint(centerXAnchor.constraint(equalTo: anchor, constant: padding))
    }
}
