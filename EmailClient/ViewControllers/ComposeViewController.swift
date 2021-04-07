//
//  ComposeViewController.swift
//  EmailClient
//
//  Created by SV on 15/03/21.
//

import UIKit

class ComposeViewController: UIViewController {
    // MARK: Views

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let (toTextField, subjectTextField) = (ComposeViewController.textFieldWithPrefix("To"), ComposeViewController.textFieldWithPrefix("Subject"))
    private let textView = ComposeViewController.textView()

    convenience init(service: SyncService, email _: String, subject _: String, body _: String) {
        self.init(service: service)
    }

    init(service: SyncService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: Private

    private let service: SyncService
}

// MARK: Setup Views

extension ComposeViewController {
    private func setupViews() {
        toTextField.text = "srinivasanv@flock.com"
        subjectTextField.text = "Subject"

        setupTableView()
        setupNavigationBar()

        view.backgroundColor = .systemBackground
    }

    private func setupTableView() {
        view.addSubview(tableView)

        tableView.embed(inSafeAreaOf: view)
        tableView.rowHeight = 44
        (tableView.dataSource, tableView.delegate) = (self, self)
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "paperplane"), style: .done, target: self, action: #selector(sendMessage)),
            UIBarButtonItem(image: UIImage(systemName: "paperclip"), style: .done, target: self, action: #selector(selectAttachments)),
        ]
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
}

// MARK: TableView Data Source

extension ComposeViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        3
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(toTextField)
            toTextField.embed(in: cell.contentView.safeAreaLayoutGuide, withPadding: 10)
        case 1:
            cell.contentView.addSubview(subjectTextField)
            subjectTextField.embed(in: cell.contentView.safeAreaLayoutGuide, withPadding: 10)
        case 2:
            cell.contentView.addSubview(textView)
            textView.embed(in: cell.contentView.safeAreaLayoutGuide, withPadding: 10)
        default:
            fatalError("Only 3 rows")
        }
        return cell
    }
}

// MARK: TableView Delegate

extension ComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0, 1:
            return 44
        case 2:
            return tableView.frame.height - 2 * 44
        default:
            fatalError("No such row")
        }
    }
}

private extension ComposeViewController {
    static func textFieldWithPrefix(_ prefix: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = prefix
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }

    static func textView() -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 20)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }
}

extension ComposeViewController {
    private func buildRawMessage() -> String? {
        guard let to = toTextField.text, let subject = subjectTextField.text, let contents = textView.text else {
            return nil
        }
        let builder = MessageBuilder()
        let rawMessage = builder.contents(contents).to(to).subject(subject).rawMessage()
        return rawMessage
    }
}

// MARK: Validation

extension ComposeViewController {
    private func validate() -> Bool {
        let alertController = UIAlertController(title: "Alert", message: "Email Cannot be blank", preferredStyle: .alert)
        var err = false

        defer {
            if err {
                let gobackAction = UIAlertAction(title: "Go Back", style: .destructive, handler: { _ in })
                alertController.addAction(gobackAction)
                present(alertController, animated: true, completion: nil)
            }
        }

        guard !(toTextField.text?.isEmpty ?? true) else {
            alertController.message = "Receiver Email cannot be blank"
            err = true
            return false
        }
        guard !(subjectTextField.text?.isEmpty ?? true) else {
            alertController.message = "Subject cannot be blank"
            err = true
            return false
        }
        guard !textView.text.isEmpty else {
            alertController.message = "Message Body cannot be blank"
            err = true
            return false
        }

        return true
    }
}

// MARK: Navigation Button Actions

extension ComposeViewController {
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func selectAttachments() {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [.fileURL, .folder, .pdf])
        vc.allowsMultipleSelection = true
        vc.delegate = self
        present(vc, animated: true)
    }

    @objc private func sendMessage() {
        guard validate() else { return }
        guard let raw = buildRawMessage() else { return }

        service.sendMessage(raw) {
            _ in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ComposeViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach {
            print($0)
        }
    }
}
