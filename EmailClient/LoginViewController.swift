//
//  ViewController.swift
//  EmailClient
//
//  Created by SV on 08/02/21.
//

import GoogleSignIn
import UIKit

class LoginViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var signInButton: GIDSignInButton!

    var user: GIDGoogleUser!

    @IBOutlet var customSignInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        activityIndicator.isHidden = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignInGoogle(_:)),
            name: .signInGoogleCompleted,
            object: nil
        )
        activityIndicator.hidesWhenStopped = true
    }

    override func viewDidAppear(_: Bool) {
        updateScreen()
    }

    func updateScreen() {
        if let user = GIDSignIn.sharedInstance()?.currentUser {
            signInButton.isHidden = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            let vc = storyboard?.instantiateViewController(identifier: "folderVC") as! FolderViewController
            // navigationController?.pushViewController(vc, animated: true)
            Networker.token = user.authentication!.accessToken!
            print(user.authentication!.accessToken!)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .flipHorizontal
            // present(vc, animated: true)

            //
            let vc2 = storyboard?.instantiateViewController(identifier: "menuNavVC") as! UIViewController
            vc2.modalPresentationStyle = .fullScreen
            present(vc2, animated: true)
        } else {
            signInButton.isHidden = false
            activityIndicator.stopAnimating()
        }
    }

    @objc private func userDidSignInGoogle(_: Notification) {
        updateScreen()
    }
}
