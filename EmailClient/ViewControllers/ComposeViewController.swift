//
//  ComposeViewController.swift
//  EmailClient
//
//  Created by SV on 15/03/21.
//

import UIKit

class ComposeViewController: UIViewController {
    let stackView = UIStackView(frame: .zero)
    let to = (label: UILabel(), textField: UITextField())
    let subject = (label: UILabel(), textField: UITextField())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(to.label)
        view.addSubview(to.textField)
        view.addSubview(subject.label)
        view.addSubview(subject.textField)

        // view.addSubview(stackView)
        view.backgroundColor = .white

        to.label.text = "To"
        subject.label.text = "Subject"
        // to.label.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        // to.label.backgroundColor = .systemBlue

        to.label.translatesAutoresizingMaskIntoConstraints = false
        to.textField.translatesAutoresizingMaskIntoConstraints = false
        subject.label.translatesAutoresizingMaskIntoConstraints = false
        subject.textField.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        to.textField.borderStyle = .roundedRect
        subject.textField.borderStyle = .bezel

        // setupConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupConstraints()
    }

    func setupConstraints() {
        // stackView.frame = view.bounds
        // NSLayoutConstraint.activate([
        //     stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
        //     stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        //     stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
        //     stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
        // ])
        NSLayoutConstraint.activate([
            to.label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            to.textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            to.label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            to.textField.centerYAnchor.constraint(equalTo: to.label.centerYAnchor),
        ])
        NSLayoutConstraint.activate([
            subject.label.leadingAnchor.constraint(equalTo: to.label.leadingAnchor),
            subject.label.topAnchor.constraint(equalTo: to.label.bottomAnchor, constant: 10),
        ])
        NSLayoutConstraint.activate([
            subject.textField.leadingAnchor.constraint(equalTo: subject.label.trailingAnchor, constant: 10),
            to.textField.leadingAnchor.constraint(equalTo: subject.textField.leadingAnchor),
            subject.textField.topAnchor.constraint(equalTo: subject.label.topAnchor),
            subject.textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
        ])
    }
}
