//
//  MenuTableViewController.swift
//  EmailClient
//
//  Created by SV on 19/02/21.
//

import CoreData
import GoogleSignIn
import MessageUI
import UIKit

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

final class MenuViewController: UIViewController {
    weak var labelSelectionDelegate: LabelSelectionDelegate?
    private let systemLabelSection = 0, userLabelSection = 1

    private var vcOf = [String: FolderViewController]()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let service: SyncService

    init(service: SyncService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)

        setupStaticViewControllers()
        setupFRC()
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

    var frc: NSFetchedResultsController<LabelMO>!
}

extension MenuViewController {
    private func setupFRC() {
        let request = LabelMO.userLabelFetchRequest
        request.returnsObjectsAsFaults = false
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        frc = NSFetchedResultsController<LabelMO>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        configureUserLabels(frc.fetchedObjects!)
    }

    private func configureUserLabels(_ labels: [LabelMO]) {
        guard menuSections[userLabelSection].count == 0 else { return }

        for label in labels {
            menuSections[userLabelSection].append(.label(id: label.id, name: label.name))
            guard let color = label.color, let colour = UIColor(hex: color) else { continue }
            imageForLabelId[label.id] = UIImage(color: colour)
            vcOf[label.id] = FolderViewController(service: service, label: (id: label.id, name: label.name))
        }
    }
}

extension MenuViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        configureUserLabels(frc.fetchedObjects!)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension MenuViewController {
    private func setupStaticViewControllers() {
        for menuItem in menuSections[systemLabelSection] {
            if case let .label(id, name) = menuItem {
                vcOf[id] = FolderViewController(service: service, label: (id: id, name: name))
            }
        }
    }

    var primaryViewController: FolderViewController {
        vcOf["INBOX"]!
    }
}

// MARK: Setup Views

private extension MenuViewController {
    private func setupViews() {
        setupTableView()
        setupNavigationBar()
        view.backgroundColor = tableView.backgroundColor
        navigationController?.navigationBar.backgroundColor = tableView.backgroundColor
    }

    private func setupTableView() {
        tableView.register(MenuTableViewCell.self, forCellReuseIdentifier: MenuTableViewCell.identifier)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        (tableView.delegate, tableView.dataSource) = (self, self)
        tableView.embed(inSafeAreaOf: view)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.backgroundColor = .systemBackground
        title = "Menu"

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil.circle"), style: .done, target: self, action: #selector(clickComposeMail))
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

// MARK: TableView Data Source

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
            cell.accessoryType = .disclosureIndicator
        case let .other(label):
            cell.configure(withLabelText: label.capitalized)
        }

        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            // tableView.deselectRow(at: indexPath, animated: true)
        }
        let item = menuSections[indexPath.section][indexPath.row]
        switch item {
        case let .label(id, name):
            guard let vc = vcOf[id] else {
                NSLog("ViewController for label(id: \(id), name: \(name)) does not exist")
                return
            }
            labelSelectionDelegate?.didSelect(label: (id: id, name: name), withVC: vc)
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
        let vc = UINavigationController(rootViewController: ComposeViewController(service: service))
        vc.isModalInPresentation = true
        present(vc, animated: true) {
            print("completed")
        }
    }
}

protocol LabelSelectionDelegate: class {
    func didSelect(label: (id: String, name: String), withVC vc: FolderViewController)
}

private extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) {
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
