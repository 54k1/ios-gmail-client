//
//  ComposeViewController.swift
//  EmailClient
//
//  Created by SV on 15/03/21.
//

import UIKit

class ComposeViewController: UIViewController {
    private let stackView = UIStackView()
    private let to = (label: UILabel(), textField: UITextField(), row: UIView())
    private let subject = (label: UILabel(), textField: UITextField(), row: UIView())

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStackView()

        // view.addSubview(stackView)
        view.backgroundColor = .white

        to.label.text = "To"
        subject.label.text = "Subject"

//        to.label.translatesAutoresizingMaskIntoConstraints = false
//        to.textField.translatesAutoresizingMaskIntoConstraints = false
//        subject.label.translatesAutoresizingMaskIntoConstraints = false
//        subject.textField.translatesAutoresizingMaskIntoConstraints = false
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        to.textField.borderStyle = .roundedRect
//        subject.textField.borderStyle = .bezel
    }
}

extension ComposeViewController {
    private func setupStackView() {
        setupToRow()
        setupSubjectRow()
        stackView.axis = .vertical
        stackView.addArrangedSubview(to.row)
        stackView.addArrangedSubview(subject.row)

        view.addSubview(stackView)
        stackView.embed(in: view.safeAreaLayoutGuide)
    }

    private func setupToRow() {
        to.row.addSubview(to.label)
        to.row.addSubview(to.textField)

        to.label.alignCenterY(to: to.textField.centerYAnchor)
        to.label.alignLeading(to: to.row.leadingAnchor)
        to.textField.alignLeading(to: to.label.trailingAnchor, withPadding: 20)
    }

    private func setupSubjectRow() {
        subject.row.addSubview(subject.label)
        subject.row.addSubview(subject.textField)

        subject.label.alignCenterY(to: subject.textField.centerYAnchor)
        subject.label.alignLeading(to: subject.row.leadingAnchor)
        subject.textField.alignLeading(to: subject.label.trailingAnchor, withPadding: 20)
    }
}
