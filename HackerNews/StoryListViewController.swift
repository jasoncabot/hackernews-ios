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

        displayLoadingActivity(true)
        self.storiesSource.load {
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

                    if let story = storiesSource.findStory(path.row) {
                        
                        (segue.destinationViewController as StoryViewController).story = story
                        (segue.destinationViewController as StoryViewController).storiesSource = storiesSource
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.onViewStory(story, indexPath: path)
                        }
                    }
                }
                
            case "ShowComments":
                let storyId = (sender as ViewCommentsButton).key!
                
                if let story:Story = storiesSource.findStory(storyId) {
                    let navigationController:UINavigationController = segue.destinationViewController as UINavigationController;
                    let commentsViewController:CommentListViewController = navigationController.viewControllers.first as CommentListViewController;
                    
                    storiesSource!.retrieveComments(story) { comments in
                        commentsViewController.onCommentsLoaded(comments)
                    }
                }
                
            default:
                break
                
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.storiesSource.isLoading {
            return
        }
        
        var percentScrolled = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.height)
        if percentScrolled > 0.9 {
            
            self.displayLoadingActivity(true)
            
            self.currentPage++
            
            self.storiesSource.load(self.currentPage) {
                self.storiesTableView.reloadData()
                self.storiesTableView.flashScrollIndicators()
                self.displayLoadingActivity(false)
            }
        }
    }
    
    private func displayLoadingActivity(show:Bool) -> Void {
        var inset = self.storiesTableView.contentInset
        inset.bottom = show ? loadingView.bounds.size.height : 0
        self.storiesTableView.contentInset = inset
        
        loadingView.alpha = show ? 0 : 1
        UIView.animateWithDuration(0.25) {
            self.loadingView.alpha = show ? 1.0 : 0.0
        }
    }
    
    private func onViewStory(story:Story, indexPath:NSIndexPath) {
        story.unread = false
    }

}