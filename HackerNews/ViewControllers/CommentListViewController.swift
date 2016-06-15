//
//  CommentListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class CommentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var commentsTableView: UITableView!
    
    var story:Story?
    var comments:[Comment]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableViewAutomaticDimension
    }

    func onCommentsLoaded(story:Story, receivedComments:[Comment]) {
        self.story = story
        self.comments = receivedComments
        
        story.commentsUnread = false
        
        commentsTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:CommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCellIdentifier", forIndexPath: indexPath) as! CommentCell

        if let comment = self.commentForRow(indexPath.row) {
            cell.updateWithComment(comment)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let comment = commentForRow(indexPath.row) where comment.externalLinks.count > 0 else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        for externalLink in comment.externalLinks {
            alertController.addAction(UIAlertAction(title: externalLink.title, style: .Default, handler: { (action:UIAlertAction) -> Void in
                if let url = NSURL(string: externalLink.url) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }))
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (comments ?? []).count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return story?.title
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.shadowOffset = CGSizeZero
            header.textLabel!.font = UIFont.systemFontOfSize(12)
            
            if let nav = self.navigationController as? HeadedNavigationController {
                header.alpha = nav.startingAlpha
            }
        }
    }
    
    func commentForRow(index:Int) -> Comment? {
        return comments?[index]
    }
    
    var onDismissed:dispatch_block_t?
    
    @IBAction func dismiss(sender: AnyObject) {
        if let closed = onDismissed {
            closed()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}