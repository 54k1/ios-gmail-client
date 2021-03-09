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

protocol MenuItemSelectionDelegate {
    func didSelectMenuItem(_ item: MenuItem)
}

class MenuTableViewController: UITableViewController {
    let menuSections: [[MenuItem]] = [
        [.label(id: "INBOX", name: "inbox"),
         .label(id: "SENT", name: "sent"),
         .label(id: "DRAFT", name: "draft"),
         .label(id: "TRASH", name: "trash")],
    ]

    var vcOf = [String: UIViewController]()
    var vc: FolderViewController!
    var uuidOf = [String: UUID]()

    @IBOutlet var composeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Menu"
        composeButton.addTarget(self, action: #selector(presentComposeVC), for: .touchUpInside)

        vc = storyboard?.instantiateViewController(identifier: "folderVC") as? FolderViewController
        guard vc != nil else {
            fatalError("Could not isntantiate 'folderVC'")
        }

        Model.shared.fetchLabels()
        // navigationController?.pushViewController(inboxVC, animated: true)
        // Model.shared.registerContext(withLabelIds: [])
        vc.label = (id: "INBOX", name: "inbox")
        tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        // navigationController?.pushViewController(vc, animated: true)
    }

    @objc func presentComposeVC() {
        guard let vc = storyboard?.instantiateViewController(identifier: "messageComposeVC") else {
            return
        }
        // navigationController?.pushViewController(vc, animated: true)
        present(vc, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        menuSections.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuSections[section].count
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        let cell = UITableViewCell()
        cell.textLabel?.text = menuSections[indexPath.section][indexPath.row].displayName

        return cell
    }

    var labelShouldFullSync = [UUID: Bool]()
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        case .other:
            print("do something based on what it is (signOut, etc.)")
        }
    }
}
