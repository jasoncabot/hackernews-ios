//
//  MenuViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit
import Crashlytics

class MenuViewController: UITableViewController {
    
    @IBOutlet weak var linkHandlingDetail: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: animated)
        }

        linkHandlingDetail.text = UserDefaults.standard.string(forKey: LinkHandlingSegue.key) ?? LinkHandlingSegue.defaultValue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier, ["FrontPage", "New", "Show", "Ask"].contains(id) else {
            return
        }
        
        guard let type = StoryType(rawValue: id) else {
            return
        }
        
        Answers.logCustomEvent(withName: "Section Loaded", customAttributes: ["Section":"\(id)"])

        (segue.destination as! StoryListViewController).storiesSource = StoriesDataSource(type: type)
    }
}
