//
//  MenuViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: animated)
        }

        if let nav = self.navigationController {
            nav.setToolbarHidden(true, animated: animated)
        }
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
}
