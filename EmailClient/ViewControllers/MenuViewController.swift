//
//  MenuTableViewController.swift
//  EmailClient
//
//  Created by SV on 19/02/21.
//

import GoogleSignIn
import UIKit

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex

        if hexString.hasPrefix("#") { // Remove the '#' prefix if added.
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            hexString = String(hexString[start...])
        }

        if hexString.lowercased().hasPrefix("0x") { // Remove the '0x' prefix if added.
            let start = hexString.index(hexString.startIndex, offsetBy: 2)
            hexString = String(hexString[start...])
        }

        let r, g, b, a: CGFloat
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else { return nil } // Make sure the strinng is a hex code.

        switch hexString.count {
        case 3, 4: // Color is in short hex format
            var updatedHexString = ""
            hexString.forEach { updatedHexString.append(String(repeating: String($0), count: 2)) }
            hexString = updatedHexString
            self.init(hex: hexString)

        case 6: // Color is in hex format without alpha.
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
            a = 1.0
            self.init(red: r, green: g, blue: b, alpha: a)

        case 8: // Color is in hex format with alpha.
            r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x0000_00FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)

        default: // Invalid format.
            return nil
        }
    }
}

class MenuViewController: UIViewController {
    static let storyboardID = "MenuViewController"
    static let navigationControllerStoryboardID = "MenuViewNavigationController"

    private enum MenuItem {
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

    private var menuSections: [[MenuItem]] = [
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

    private var imageForLabelId: [String: UIImage] = [
        "INBOX": UIImage(systemName: "envelope")!,
        "SENT": UIImage(systemName: "hand.point.right")!,
        "STARRED": UIImage(systemName: "star")!,
        "DRAFT": UIImage(systemName: "pencil.and.ellipsis.rectangle")!,
        "TRASH": UIImage(systemName: "trash")!,
    ]

    private var folderViewController = FolderViewController()
    private var uuidOf = [String: UUID]()
    private var labelShouldFullSync = [UUID: Bool]()
    private let systemLabelSection = 0
    private let userLabelSection = 1

    private let tableView: UITableView = {
        let view = UITableView()
        view.register(MenuTableViewCell.self, forCellReuseIdentifier: MenuTableViewCell.identifier)
        view.tableFooterView = UIView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupLabels()
    }
}

extension MenuViewController {
    private func setupNavigationBar() {
        title = "Menu"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil.circle"), style: .done, target: self, action: #selector(clickComposeMail))
    }
}

extension MenuViewController {
    private func setupViews() {
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        (tableView.delegate, tableView.dataSource) = (self, self)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        Constraints.embed(tableView, in: view)
    }
}

extension MenuViewController {
    private func setupLabels() {
        Model.shared.fetchLabels {
            labelsListResponse in
            for label in labelsListResponse.labels {
                guard case .user = label.type else {
                    continue
                }
                self.menuSections[self.userLabelSection].append(.label(id: label.id, name: label.name))
                let color = UIColor(hex: label.color!.backgroundColor)!
                self.imageForLabelId[label.id] = UIImage(color: color, size: CGSize(width: 10, height: 10))
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        menuSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuSections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as! MenuTableViewCell
        switch menuSections[indexPath.section][indexPath.row] {
        case let .label(id, _):
            if let image = imageForLabelId[id] {
                cell.configure(withLabelText: menuSections[indexPath.section][indexPath.row].displayName.capitalized, withImage: image)
            } else {
                cell.configure(withLabelText: menuSections[indexPath.section][indexPath.row].displayName.capitalized, withImage: UIImage(color: .systemPink, size: CGSize(width: 10, height: 10))!)
            }
        // let image = UIImage(color: .systemRed, size: CGSize(width: 10, height: 10))!
        case let .other(label):
            cell.configure(withLabelText: label)
        }

        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = menuSections[indexPath.section][indexPath.row]
        switch item {
        case let .label(id, name):
            print(item)
            folderViewController.label = (id, name)
            folderViewController.title = name.capitalized
            if let uuid = uuidOf[id] {
                // If context already registered, simply change it
                Model.shared.changeContext(toUUID: uuid)
            } else {
                // Else register new Context and store obtained UUID
                let uuid = Model.shared.registerContext(withLabelIds: [id])
                uuidOf[id] = uuid
                Model.shared.changeContext(toUUID: uuid)
                folderViewController.performInitialFullSync()
            }
            navigationController?.pushViewController(folderViewController, animated: true)
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

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension MenuViewController {
    @objc func clickComposeMail() {
        // print("click compose mail")
        navigationController?.pushViewController(ComposeViewController(), animated: true)
    }
}
