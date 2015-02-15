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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            switch id {
                
            case "ShowStory":
                let path = storiesTableView.indexPathForSelectedRow();
                
                if path != nil {
                    let index = (path?.row)!
                    (segue.destinationViewController as StoryViewController).storiesSource = storiesSource
                    (segue.destinationViewController as StoryViewController).story = storiesSource.findStory(index)
                }
                
            case "ShowComments":
                var story:Story = storiesSource.findStory((sender as ViewCommentsButton).key!)
                let navigationController:UINavigationController = segue.destinationViewController as UINavigationController;
                let commentsViewController:CommentListViewController = navigationController.viewControllers.first as CommentListViewController;
                
                commentsViewController.comments = storiesSource!.retrieveComments(story)
                
            default:
                break
                
            }
        }
    }

}