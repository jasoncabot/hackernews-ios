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

    var story:Story?;
    
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
}
