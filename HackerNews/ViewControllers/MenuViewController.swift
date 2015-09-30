//
//  MenuViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(path, animated: animated)
        }

        if let nav = self.navigationController {
            nav.setToolbarHidden(true, animated: animated)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let id = segue.identifier where ["FrontPage", "New", "Show", "Ask"].contains(id) else {
            return
        }
        
        guard let type = StoryType(rawValue: id) else {
            return
        }
        
        (segue.destinationViewController as! StoryListViewController).storiesSource = StoriesDataSource(type: type)
    }
}