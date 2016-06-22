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
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var sortButton: UIBarButtonItem!

    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var sortingLabel: UILabel!
    
    var storiesSource:StoriesDataSource!
    var currentPage:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = storiesSource.title
        storiesTableView.estimatedRowHeight = 72
        storiesTableView.rowHeight = UITableViewAutomaticDimension
        
        toastView.layer.cornerRadius = 20
        
        storiesTableView.dataSource = storiesSource
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(StoryListViewController.refreshStories(_:)), forControlEvents: .ValueChanged)
        storiesTableView.insertSubview(refreshControl, atIndex: 0)

        displayLoadingActivity(true)
        storiesSource.load {
            self.currentPage = 1
            self.displayLoadingActivity(false)
            self.storiesTableView.reloadData()
        }
    }
    
    @IBAction func refreshStories(sender: UIRefreshControl) {
        
        // fade out our old stories
        UIView.animateWithDuration(1) {
            self.storiesTableView.alpha = 0.2
        }
        
        // load in our new ones
        storiesSource.refresh {
            sender.endRefreshing()
            self.currentPage = 1
            self.storiesTableView.reloadData()
            self.storiesTableView.flashScrollIndicators()
            UIView.animateWithDuration(0.25) {
                self.storiesTableView.alpha = 1
            }
        }
    }

    @IBAction func changeSortOrder(sender: UIBarButtonItem) {
        
        storiesTableView.scrollToRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        
        let updates = storiesSource.updatedIndexPathsByChangingSortOrdering()
        
        storiesTableView.beginUpdates()
        updates.forEach { (from, to) in
            self.storiesTableView.moveRowAtIndexPath(from, toIndexPath: to)
        }
        storiesTableView.endUpdates()
        
        if let visiblePaths = storiesTableView.indexPathsForVisibleRows {
            for path in visiblePaths {
                if let cell = storiesTableView.cellForRowAtIndexPath(path) as? StoryCell, let story = storiesSource.storyForIndexPath(path) {
                    cell.updateWithStory(story)
                }
            }
        }
        
        self.sortingLabel.text = "\(storiesSource.sorting)"
        self.toastView.alpha = 0
        UIView.animateWithDuration(0.25, animations: { 
            self.toastView.alpha = 1
        }) { done in
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.25) {
                    self.toastView.alpha = 0
                }
            }
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let path = storiesTableView.indexPathForSelectedRow {
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
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if !storiesSource.isLoading {
            let shouldLoadMore = indexPath.row >= storiesSource.stories.count - 10

            if shouldLoadMore {
                
                displayLoadingActivity(true)
                currentPage = currentPage + 1
                storiesSource.load(currentPage) {
                    self.storiesTableView.reloadData()
                    self.storiesTableView.flashScrollIndicators()
                    self.displayLoadingActivity(false)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let story = storiesSource.storyForIndexPath(storiesTableView.indexPathForSelectedRow), url = story.url else {
            return
        }
        
        let browser = BrowserViewController(URL: url, entersReaderIfAvailable: false)
        
        browser.story = story
        browser.storiesSource = storiesSource
        
        self.navigationController?.pushViewController(browser, animated: true)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            switch id {
                
            case "ShowComments":
                let storyId = (sender as! ViewCommentsButton).key

                guard let story = storiesSource.findStory(storyId) else {
                    return
                }
                
                let navigationController:UINavigationController = segue.destinationViewController as! UINavigationController;
                let commentsViewController:CommentListViewController = navigationController.viewControllers.first as! CommentListViewController;
                
                commentsViewController.onDismissed = {
                    commentsViewController.onDismissed = nil
                    if let path = self.storiesSource.indexPathForStory(story) {
                        self.storiesTableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
                    }
                }
                
                showNetworkIndicator(true)
                storiesSource.retrieveComments(story) { comments in
                    self.showNetworkIndicator(false)
                    commentsViewController.onCommentsLoaded(story, receivedComments: comments)
                }
                
            default:
                break
                
            }
        }
    }

    private func showNetworkIndicator(show:Bool) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).networkIndicator.displayNetworkIndicator(show)
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