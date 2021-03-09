//
//  MenuViewController.swift
//  EmailClient
//
//  Created by SV on 03/03/21.
//

import UIKit

/*
 All Mail
 -----------
 Labels
    Starred
    Sent
    Trashed
    ...
 -----------
 Settings
 SignOut
 */

class MenuViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

extension MenuViewController: UICollectionViewDelegate {}

extension MenuViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        1
    }

    func collectionView(_: UICollectionView, cellForItemAt _: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
