//
//  BrowserViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/06/2016.
//  Copyright © 2016 Jason Cabot. All rights reserved.
//

import SafariServices

class BrowserViewController : SFSafariViewController {

    var store: ReadStore = ReadStore.memory
    var story:Story?
    var storiesSource:StoriesDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 10.0, *) {
            self.preferredControlTintColor = UIColor(colorLiteralRed: 0xD0 / 0xFF, green: 0x30 / 0xFF, blue: 0x44 / 0xFF, alpha: 1.0)
        } else {
            self.view.tintColor = UIColor(colorLiteralRed: 0xD0 / 0xFF, green: 0x30 / 0xFF, blue: 0x44 / 0xFF, alpha: 1.0)
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Comments", style: .plain, target: self, action: #selector(BrowserViewController.showComments(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let story = story { store.viewed(story: story) }

        UIApplication.shared.statusBarStyle = .default
        if isBeingPresented {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
        if isBeingDismissed {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        super.viewWillDisappear(animated)
    }

    @IBAction func showComments(_ sender: UIBarButtonItem) {
        guard let story = self.story, let source = self.storiesSource else {
            return
        }

        let navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommentNavigationController") as! UINavigationController
        let commentsViewController = navigationController.viewControllers.first as! CommentListViewController
        
        showNetworkIndicator(true)
        source.retrieveComments(story) { comments in
            self.showNetworkIndicator(false)
            commentsViewController.onCommentsLoaded(story, receivedComments: comments)
        }
        
        self.navigationController?.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func showNetworkIndicator(_ show:Bool) {
        (UIApplication.shared.delegate as! AppDelegate).networkIndicator.displayNetworkIndicator(show)
    }
}
