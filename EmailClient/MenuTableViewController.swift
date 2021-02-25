//
//  MenuTableViewController.swift
//  EmailClient
//
//  Created by SV on 19/02/21.
//

import GoogleSignIn
import UIKit

protocol MenuItemSelectionDelegate {
    func didSelectMenuItem(_ item: MenuTableViewController.MenuItem)
}

class MenuTableViewController: UITableViewController {
    enum MenuItem: String {
        case inbox, sent, trash
        case signOut
    }

    let menuSections: [[MenuItem]] = [
        [.inbox, .sent, .trash],
        [.signOut],
    ]

    var vcOf = [MenuItem: UIViewController]()

    @IBOutlet var composeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Menu"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        composeButton.addTarget(self, action: #selector(presentComposeVC), for: .touchUpInside)

        guard let inboxVC = storyboard?.instantiateViewController(identifier: "folderVC") else {
            return
        }
        guard let sentVC = storyboard?.instantiateViewController(identifier: "folderVC") as? FolderViewController else {
            return
        }
        guard let trashVC = storyboard?.instantiateViewController(identifier: "folderVC") as? FolderViewController else {
            return
        }
        sentVC.setKind(.sent)
        trashVC.setKind(.trash)
        vcOf[.inbox] = inboxVC
        vcOf[.sent] = sentVC
        vcOf[.trash] = trashVC
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
        cell.textLabel?.text = menuSections[indexPath.section][indexPath.row].rawValue.capitalized

        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = menuSections[indexPath.section][indexPath.row]
        switch item {
        case .inbox, .sent, .trash:
            let vc = vcOf[item]!
            navigationController?.pushViewController(vc, animated: true)
        case .signOut:
            GIDSignIn.sharedInstance()?.signOut()
            dismiss(animated: true, completion: nil)
        }
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the specified item to be editable.
         return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
         if editingStyle == .delete {
             // Delete the row from the data source
             tableView.deleteRows(at: [indexPath], with: .fade)
         } else if editingStyle == .insert {
             // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the item to be re-orderable.
         return true
     }
     */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
