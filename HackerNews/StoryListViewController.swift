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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = storiesSource.title()

        self.storiesSource.load {
            self.storiesTableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let path = storiesTableView.indexPathForSelectedRow() {
            storiesTableView.deselectRowAtIndexPath(path, animated: animated)
            
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            dispatch_after(after, dispatch_get_main_queue(), { () -> Void in
                self.storiesTableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Fade)
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            switch id {
                
            case "ShowStory":

                if let path = storiesTableView.indexPathForSelectedRow() {

                    if let story = storiesSource.findStory(path.row) {
                        
                        (segue.destinationViewController as StoryViewController).story = story
                        (segue.destinationViewController as StoryViewController).storiesSource = storiesSource
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.onViewStory(story, indexPath: path)
                        })
                    }
                }
                
            case "ShowComments":
                let storyId = (sender as ViewCommentsButton).key!
                
                if let story:Story = storiesSource.findStory(storyId) {
                    let navigationController:UINavigationController = segue.destinationViewController as UINavigationController;
                    let commentsViewController:CommentListViewController = navigationController.viewControllers.first as CommentListViewController;
                    
                    commentsViewController.comments = storiesSource!.retrieveComments(story)
                }
                
            default:
                break
                
            }
        }
    }
    
    private func onViewStory(story:Story, indexPath:NSIndexPath) {
        story.unread = false
    }

}