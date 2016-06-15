//
//  BrowserViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/06/2016.
//  Copyright © 2016 Jason Cabot. All rights reserved.
//

import SafariServices

class BrowserViewController : SFSafariViewController {
    
    var story:Story?
    var storiesSource:StoriesDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.tintColor = UIColor(colorLiteralRed: 0xD0 / 0xFF, green: 0x30 / 0xFF, blue: 0x44 / 0xFF, alpha: 1.0)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Comments", style: .Plain, target: self, action: #selector(BrowserViewController.showComments(_:)))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.story?.unread = false
    }
    
    @IBAction func showComments(sender: UIBarButtonItem) {
        guard let story = self.story, source = self.storiesSource else {
            return
        }

        let navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("CommentNavigationController") as! UINavigationController
        let commentsViewController = navigationController.viewControllers.first as! CommentListViewController
        
        showNetworkIndicator(true)
        source.retrieveComments(story) { comments in
            self.showNetworkIndicator(false)
            commentsViewController.onCommentsLoaded(story, receivedComments: comments)
        }
        
        self.navigationController?.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    private func showNetworkIndicator(show:Bool) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).networkIndicator.displayNetworkIndicator(show)
    }
}