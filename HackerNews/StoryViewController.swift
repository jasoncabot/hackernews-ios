//
//  StoryViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryViewController : UIViewController, UIWebViewDelegate, OptionalToolbarViewController {
    @IBOutlet var webView:UIWebView!
    @IBOutlet var safariButton: UIBarButtonItem!

    var story:Story?
    var storiesSource:StoriesDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.story?.title
        
        if let storyUrl = self.story?.url {
            var request = NSURLRequest(URL: storyUrl)
            
            self.webView.loadRequest(request);
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nav = self.navigationController {
            nav.setToolbarHidden(nav.navigationBarHidden, animated: animated)
        }
    }
    
    func shouldDisplayToolbar() -> Bool {
        return true;
    }
    
    @IBAction func openInSafari(sender: UIBarButtonItem) {
        if let storyUrl = self.story?.url {
            UIApplication.sharedApplication().openURL(storyUrl)
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

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        (UIApplication.sharedApplication().delegate as AppDelegate).networkIndicator.displayNetworkIndicator(false)
    }

    func webViewDidStartLoad(webView: UIWebView) {
        (UIApplication.sharedApplication().delegate as AppDelegate).networkIndicator.displayNetworkIndicator(true)
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        (UIApplication.sharedApplication().delegate as AppDelegate).networkIndicator.displayNetworkIndicator(false)
    }
}
