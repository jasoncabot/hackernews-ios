//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryListViewController: UIViewController, UITableViewDelegate {

    var dataSource:StoriesDataSource?
    
    @IBOutlet var storiesTableView: UITableView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.storiesTableView.dataSource = dataSource
        
        self.title = dataSource?.title()

        if storiesTableView.indexPathForSelectedRow() != nil {
            storiesTableView.deselectRowAtIndexPath(storiesTableView.indexPathForSelectedRow()!, animated: animated)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dataSource = nil
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var story:Story? = self.dataSource?.findStory(indexPath.row)
        
        if story != nil {
            println(story)
        }
    }

}