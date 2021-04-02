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
        let context = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        let ctx = persistentContainer.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        service = SyncService(authorizationValue: authorizationValue, context: ctx)
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
    func didSelect(_ thread: ViewModel.Thread) {
        guard let vc = viewController(for: .secondary) as? ThreadDetailViewController else {
            return
        }
        vc.didSelect(thread)
        show(.secondary)
    }
}
