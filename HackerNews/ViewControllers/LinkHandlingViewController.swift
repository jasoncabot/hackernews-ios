//
//  LinkHandlingViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 22/12/2017.
//  Copyright © 2017 Jason Cabot. All rights reserved.
//

import UIKit

class LinkHandlingViewController: UITableViewController {

    @IBOutlet weak var external: UITableViewCell!
    @IBOutlet weak var inapp: UITableViewCell!

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                               object: nil,
                                               queue: OperationQueue.main) { (note) in
            self.reload()
        }

        reload()
    }



    // MARK: LinkHandlingViewController

    func reload() {
        let option = UserDefaults.standard.string(forKey: "LinkHandling")

        if option == LinkHandlingSegue.InApp {
            external.accessoryType = .none
            inapp.accessoryType = .checkmark
        } else {
            external.accessoryType = .checkmark
            inapp.accessoryType = .none
        }

        tableView.reloadData()
    }
}
