//
//  MenuViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {
    
    @IBOutlet weak var linkHandlingDetail: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = #colorLiteral(red: 1, green: 0.4, blue: 0, alpha: 1)
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: animated)
        }

        linkHandlingDetail.text = UserDefaults.standard.string(forKey: LinkHandlingSegue.key) ?? LinkHandlingSegue.defaultValue
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier, ["FrontPage", "New", "Show", "Ask"].contains(id) else {
            return
        }
        
        guard let type = StoryType(rawValue: id) else {
            return
        }
        
        (segue.destination as! StoryListViewController).storiesSource = StoriesDataSource(type: type)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
