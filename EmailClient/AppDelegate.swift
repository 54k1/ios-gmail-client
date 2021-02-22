//
//  AppDelegate.swift
//  EmailClient
//
//  Created by SV on 08/02/21.
//

import GoogleSignIn
import UIKit
import Keys

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    func sign(_: GIDSignIn!, didSignInFor _: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ToggleAuthUINotification"), object: nil, userInfo: nil
            )
            return
        }
        // Observed by ViewController
        NotificationCenter.default.post(name: .signInGoogleCompleted, object: nil)
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!, withError _: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

    @available(iOS 9.0, *)
    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any])
        -> Bool
    {
        return GIDSignIn.sharedInstance().handle(url)
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let keys = EmailClientKeys()
        GIDSignIn.sharedInstance().clientID = keys.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.scopes.append("https://www.googleapis.com/auth/gmail.compose")
        GIDSignIn.sharedInstance()?.scopes.append("https://www.googleapis.com/auth/gmail.readonly")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - Notification names

extension Notification.Name {
    /// Notification when user successfully sign in using Google
    static var signInGoogleCompleted: Notification.Name {
        return .init(rawValue: #function)
    }
}
