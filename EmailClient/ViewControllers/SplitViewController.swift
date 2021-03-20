//
//  SplitViewController.swift
//  EmailClient
//
//  Created by SV on 18/03/21.
//

import UIKit

class SplitViewController: UISplitViewController {
    init() {
        super.init(style: .tripleColumn)
        setupViewControllers()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SplitViewController {
    func setupViewControllers() {
        let menuViewController = MenuViewController()
        let folderViewController = FolderViewController()
        let threadViewContoller = ThreadViewController()

        setViewController(menuViewController, for: .primary)
        setViewController(folderViewController, for: .supplementary)
        setViewController(threadViewContoller, for: .secondary)

        menuViewController.labelSelectionDelegate = self
        folderViewController.threadSelectionDelegate = self
    }
}

extension SplitViewController: LabelSelectionDelegate {
    func didSelect(label: (id: String, name: String)) {
        guard let vc = viewController(for: .supplementary) as? FolderViewController else {
            return
        }
        vc.didSelect(label: label)
        show(.supplementary)
    }
}

extension SplitViewController: ThreadSelectionDelegate {
    func didSelect(_ threadDetail: ThreadDetail) {
        guard let vc = viewController(for: .secondary) as? ThreadViewController else {
            return
        }
        vc.didSelect(threadDetail)
        show(.secondary)
    }
}
