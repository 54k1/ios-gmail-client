//
//  ThreadViewController.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import UIKit
import WebKit

class ThreadViewController: UIViewController {
    // MARK: SubViews

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.identifier)
        return tableView
    }()

    private let subjectHeader = UILabel()

    private var threadDetail: ThreadDetail!
    private var threadId: String!
    private var heightAt = [IndexPath: CGFloat]()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // tableView.tableHeaderView = subjectHeader
    }

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        subjectHeader.translatesAutoresizingMaskIntoConstraints = false
//        subjectHeader.backgroundColor = .white
//        NSLayoutConstraint.activate([
//            subjectHeader.heightAnchor.constraint(equalToConstant: 70),
//            subjectHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
//        ])
//    }
}

extension ThreadViewController {
    func setupViews() {
        view.backgroundColor = .white
        setupTableView()
        setupHeaderView()
        addConstraints()
    }

    func addConstraints() {
        tableView.embed(in: view.safeAreaLayoutGuide)
        // Constraints.pin(tableView, to: view.safeAreaLayoutGuide.topAnchor, on: .vertical(.top))
        // Constraints.pin(tableView, to: view.safeAreaLayoutGuide.leadingAnchor, on: .horizontal(.leading))
        // Constraints.pin(tableView, to: view.safeAreaLayoutGuide.trailingAnchor, on: .horizontal(.trailing))
        // Constraints.pin(tableView, to: view.safeAreaLayoutGuide.bottomAnchor, on: .vertical(.bottom))
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = nil
        tableView.tableHeaderView = nil
        tableView.tableHeaderView = subjectHeader
    }

    func setupHeaderView() {
        view.addSubview(subjectHeader)
        subjectHeader.translatesAutoresizingMaskIntoConstraints = false
        subjectHeader.numberOfLines = 0
        // subjectHeader.attributedText = NSAttributedString(string: threadDetail.messages[0].headerValueFor(key: "Subject")!, attributes: [
        //    .strokeColor: UIColor.black,
        //    .font: UIFont.boldSystemFont(ofSize: 30),
        // ])
    }
}

extension ThreadViewController {
    func configure(with threadDetail: ThreadDetail) {
        self.threadDetail = threadDetail
        title = threadDetail.messages[0].snippet
        tableView.reloadData()
    }

    func configure(with threadId: String) {
        self.threadId = threadId
        Model.shared.fetchThread(withId: threadId) {
            threadDetail in
            DispatchQueue.main.async {
                self.threadDetail = threadDetail
            }
        }
    }
}

extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        threadDetail?.messages.count ?? 0
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.identifier, for: indexPath) as! MessageTableViewCell
        let cell = MessageTableViewCell()
        cell.layer.shadowRadius = 40
        cell.previewDelegate = self
        cell.delegate = self
        cell.indexPath = indexPath
        cell.configure(with: threadDetail.messages[indexPath.section])
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ret0 = heightAt[indexPath] ?? 44 * 4
        return ret0
    }
}

protocol ParentTableViewDelegate: class {
    func setHeight(to height: CGFloat, at indexPath: IndexPath)
}

extension ThreadViewController: ParentTableViewDelegate {
    func setHeight(to height: CGFloat, at indexPath: IndexPath) {
        heightAt[indexPath] = height
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

protocol PreviewDelegate: class {
    func shouldPresent(_ vc: UIViewController, animated: Bool)
}

extension ThreadViewController: PreviewDelegate {
    func shouldPresent(_ vc: UIViewController, animated: Bool) {
        present(vc, animated: animated)
    }
}

extension ThreadViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {}
}

extension ThreadViewController: ThreadSelectionDelegate {
    func didSelect(_ threadDetail: ThreadDetail) {
        configure(with: threadDetail)
    }
}
