//
//  SplitViewController.swift
//  EmailClient
//
//  Created by SV on 18/03/21.
//

import CoreData
import UIKit

class SplitViewController: UISplitViewController {
    let service: SyncService
    init(authorizationValue: String) {
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        service = SyncService(authorizationValue: authorizationValue, container: persistentContainer)
        super.init(style: .tripleColumn)
        self.delegate = self
        setupViewControllers()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension SplitViewController {
    func setupViewControllers() {
        let menuViewController = MenuViewController(service: service)
        let folderViewController = menuViewController.primaryViewController
        let threadViewController = ThreadDetailViewController(service: service)

        setViewController(menuViewController, for: .primary)
        setViewController(folderViewController, for: .supplementary)
        setViewController(threadViewController, for: .secondary)

        menuViewController.labelSelectionDelegate = self
        folderViewController.threadSelectionDelegate = self
    }
}

extension SplitViewController: LabelSelectionDelegate {
    func didSelect(label _: (id: String, name: String), withVC vc: FolderViewController) {
        vc.threadSelectionDelegate = self
        setViewController(vc, for: .supplementary)
        show(.supplementary)
    }
}

extension SplitViewController: ThreadSelectionDelegate {
    func didSelect(_ thread: ThreadMO) {
        guard let vc = viewController(for: .secondary) as? ThreadDetailViewController else {
            return
        }
        vc.didSelect(thread)
        show(.secondary)
    }
}

extension SplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        .primary
    }
}
