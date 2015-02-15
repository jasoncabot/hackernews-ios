//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryListViewController: UIViewController, UITableViewDelegate {

    @IBOutlet var storiesTableView: UITableView!
    @IBOutlet var storiesSource:StoriesDataSource!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.title = storiesSource.title()

        if storiesTableView.indexPathForSelectedRow() != nil {
            storiesTableView.deselectRowAtIndexPath(storiesTableView.indexPathForSelectedRow()!, animated: animated)
        }
    }

}