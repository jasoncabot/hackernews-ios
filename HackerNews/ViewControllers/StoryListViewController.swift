//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryListViewController: UIViewController, UITableViewDelegate, OptionalToolbarViewController {

    @IBOutlet var storiesTableView: UITableView!
    @IBOutlet var storiesSource:StoriesDataSource!
    @IBOutlet weak var loadingView: UIView!

    var currentPage:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = storiesSource.title()
        storiesTableView.estimatedRowHeight = 60
        storiesTableView.rowHeight = UITableViewAutomaticDimension

        displayLoadingActivity(true)
        self.storiesSource.load {
            self.currentPage = 1
            self.displayLoadingActivity(false)
            self.storiesTableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let path = storiesTableView.indexPathForSelectedRow() {
            storiesTableView.deselectRowAtIndexPath(path, animated: animated)
            
            self.storiesTableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
        }
        
        if let nav = self.navigationController {
            nav.setToolbarHidden(true, animated: animated)
        }
    }

    func shouldDisplayToolbar() -> Bool {
        return false;
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            switch id {
                
            case "ShowStory":

                if let path = storiesTableView.indexPathForSelectedRow() {

                    if let story = storiesSource.storyForIndexPath(path) {
                        
                        (segue.destinationViewController as StoryViewController).story = story
                        (segue.destinationViewController as StoryViewController).storiesSource = storiesSource
                        
                        story.unread = false
                    }
                }
                
            case "ShowComments":
                let storyId = (sender as ViewCommentsButton).key!

                if let story:Story = storiesSource.findStory(storyId) {
                    let navigationController:UINavigationController = segue.destinationViewController as UINavigationController;
                    let commentsViewController:CommentListViewController = navigationController.viewControllers.first as CommentListViewController;
                    
                    commentsViewController.onDismissed = {
                        commentsViewController.onDismissed = nil
                        if let path = self.storiesSource.indexPathForStory(story) {
                            self.storiesTableView.reloadRowsAtIndexPaths([path], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                    
                    showNetworkIndicator(true)
                    storiesSource!.retrieveComments(story) { comments in
                        self.showNetworkIndicator(false)
                        commentsViewController.onCommentsLoaded(story, receivedComments: comments)
                    }

                    story.unread = false
                }
                
            default:
                break
                
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if storiesSource.isLoading {
            return
        }
        
        var percentScrolled = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.height)
        if percentScrolled > 0.9 {
            
            displayLoadingActivity(true)
            storiesSource.load(++currentPage) {
                self.storiesTableView.reloadData()
                self.storiesTableView.flashScrollIndicators()
                self.displayLoadingActivity(false)
            }
        }
    }
    
    private func showNetworkIndicator(show:Bool) {
        (UIApplication.sharedApplication().delegate as AppDelegate).networkIndicator.displayNetworkIndicator(show)
    }
    
    private func displayLoadingActivity(show:Bool) {
        showNetworkIndicator(show)

        var inset = storiesTableView.contentInset
        inset.bottom = show ? loadingView.bounds.size.height : 0
        storiesTableView.contentInset = inset
        
        loadingView.alpha = show ? 0 : 1
        UIView.animateWithDuration(0.25) {
            self.loadingView.alpha = show ? 1.0 : 0.0
        }
    }

}