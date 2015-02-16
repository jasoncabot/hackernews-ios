//
//  StoryViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryViewController : UIViewController, UIWebViewDelegate {
    @IBOutlet var webView:UIWebView!

    var story:Story?
    var storiesSource:StoriesDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.story?.title
        
        if self.story?.url != nil {
            var request = NSURLRequest(URL: (self.story?.url)!)
            
            self.webView.loadRequest(request);
        }
    }
    
    @IBAction func openInSafari(sender: UIBarButtonItem) {
        if self.story?.url != nil {
            let externalURL = self.story?.url
            
            UIApplication.sharedApplication().openURL(externalURL!)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            switch id {
                
            case "ShowComments":
                var story:Story = self.story!
                if storiesSource != nil {
                    let navigationController:UINavigationController = segue.destinationViewController as UINavigationController;
                    let commentsViewController:CommentListViewController = navigationController.viewControllers.first as CommentListViewController;
                    
                    commentsViewController.comments = storiesSource!.retrieveComments(story)
                }
                
            default:
                break
            }
        }
    }
}
