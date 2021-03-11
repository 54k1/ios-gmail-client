//
//  ThreadViewController.swift
//  EmailClient
//
//  Created by SV on 11/03/21.
//

import UIKit

class ThreadViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.identifier)
        return tableView
    } ()
    
    private var threadDetail: ThreadDetail!
    private var threadId: String!
    private var heightAt = [IndexPath: CGFloat]()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = nil
        tableView.tableHeaderView = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // view.backgroundColor = .red
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension ThreadViewController {
    func configure(with threadDetail: ThreadDetail) {
        self.threadDetail = threadDetail
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
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.threadDetail.messages.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.identifier, for: indexPath) as! MessageTableViewCell
        cell.previewDelegate = self
        cell.delegate = self
        cell.indexPath = indexPath
        let row = indexPath.row
        cell.configure(with: threadDetail.messages[row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ret0 = heightAt[indexPath] ?? 44*4
        return ret0
    }
    
}

protocol ParentTableViewDelegate {
    func setHeight(to height: CGFloat, at indexPath: IndexPath)
}

extension ThreadViewController: ParentTableViewDelegate {
    func setHeight(to height: CGFloat, at indexPath: IndexPath) {
        heightAt[indexPath] = height
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

protocol PreviewDelegate {
    func shouldPresent(_ vc: UIViewController, animated: Bool)
}

extension ThreadViewController: PreviewDelegate {
    func shouldPresent(_ vc: UIViewController, animated: Bool) {
        present(vc, animated: animated)
    }
}
