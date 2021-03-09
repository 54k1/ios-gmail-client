//
//  MenuTableViewController.swift
//  EmailClient
//
//  Created by SV on 19/02/21.
//

import GoogleSignIn
import UIKit

enum MenuItem {
    case label(id: String, name: String)
    case other(name: String)

    var displayName: String {
        switch self {
        case let .label(_, name):
            return name
        case let .other(name):
            return name
        }
    }
}

class MenuViewController: UIViewController {
    static let storyboardID = "MenuViewController"
    static let navigationControllerStoryboardID = "MenuViewNavigationController"

    var menuSections: [[MenuItem]] = [
        // System
        [
            .label(id: "INBOX", name: "inbox"),
            .label(id: "SENT", name: "sent"),
            .label(id: "STARRED", name: "starred"),
            .label(id: "DRAFT", name: "draft"),
            .label(id: "TRASH", name: "trash"),
        ],
        [], // User
        [.other(name: "signout")],
    ]

    var vc: FolderViewController!
    var uuidOf = [String: UUID]()
    var labelShouldFullSync = [UUID: Bool]()
    let systemLabelSection = 0
    let userLabelSection = 1

    @IBOutlet var composeButton: UIButton!
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Menu"
        // composeButton.addTarget(self, action: #selector(presentComposeVC), for: .touchUpInside)

        vc = storyboard?.instantiateViewController(identifier: "folderVC") as? FolderViewController
        guard vc != nil else {
            fatalError("Could not isntantiate 'folderVC'")
        }

        tableView.dataSource = self
        tableView.delegate = self
        Model.shared.fetchLabels {
            labelsListResponse in
            for label in labelsListResponse.labels {
                if case .user = label.type {
                    self.menuSections[self.userLabelSection].append(.label(id: label.id, name: label.name))
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        // Segue into inbox automatically
        // tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        tableView.tableFooterView = UIView()
    }

    @objc func presentComposeVC() {
        guard let vc = storyboard?.instantiateViewController(identifier: "messageComposeVC") else {
            return
        }
        present(vc, animated: true)
    }
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        menuSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuSections[section].count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = menuSections[indexPath.section][indexPath.row].displayName.capitalized

        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = menuSections[indexPath.section][indexPath.row]
        switch item {
        case let .label(id, name):
            print(item)
            vc.label = (id, name)
            vc.title = name.capitalized
            if let uuid = uuidOf[id] {
                // If context already registered, simply change it
                Model.shared.changeContext(toUUID: uuid)
            } else {
                // Else register new Context and store obtained UUID
                let uuid = Model.shared.registerContext(withLabelIds: [id])
                uuidOf[id] = uuid
                Model.shared.changeContext(toUUID: uuid)
                vc.performInitialFullSync()
            }
            navigationController?.pushViewController(vc, animated: true)
        case let .other(name):
            switch name {
            case "signout":
                GIDSignIn.sharedInstance()?.signOut()
                dismiss(animated: true, completion: nil)
            // navigationController?.popViewController(animated: true)
            default:
                fatalError("Unknown operation '\(name)'")
            }
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == userLabelSection {
            // user labels
            let view = UILabel()
            view.text = "User labels"
            return view
        }
        return nil
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == userLabelSection {
            return 20
        } else {
            return 0
        }
    }
}
