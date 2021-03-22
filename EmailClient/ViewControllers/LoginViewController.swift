//
//  ViewController.swift
//  EmailClient
//
//  Created by SV on 08/02/21.
//

import GoogleSignIn
import OSLog
import UIKit

class LoginViewController: UIViewController {
    private let signInButton = GIDSignInButton()
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        view.isHidden = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignInGoogle(_:)),
            name: .signInGoogleCompleted,
            object: nil
        )
        // setupGIDSignIn()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGIDSignIn()
    }
}

extension LoginViewController {
    private func setupViews() {
        view.backgroundColor = .systemPink

        view.addSubview(signInButton)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        signInButton.center(in: view)
    }
}

extension LoginViewController {
    private func setupGIDSignIn() {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }

    @objc private func userDidSignInGoogle(_: Notification) {
        guard let user = GIDSignIn.sharedInstance()?.currentUser else {
            NSLog("User Signed in notification triggered but currentUser is nil")
            return
        }

        let vc = SplitViewController(authorizationValue: user.authentication.accessToken)
        // folderViewController.label = (id: "INBOX", name: "inbox")
        let uuid = Model.shared.registerContext(withLabelIds: ["INBOX"])
        Model.shared.changeContext(toUUID: uuid)

        // Set access token in Model
        Model.token = user.authentication.accessToken
        print("authToken = \(user.authentication.accessToken!)")

        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
