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
    var comments:Array<Comment>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        
        UITableViewHeaderFooterView.appearance().textLabel.backgroundColor = UIColor.redColor()
    }

    func onCommentsLoaded(story:Story, receivedComments:Array<Comment>) {
        self.story = story
        self.comments = receivedComments
        
        commentsTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:CommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCellIdentifier", forIndexPath: indexPath) as CommentCell

        if let comment = self.commentForRow(indexPath.row) {
            cell.updateWithComment(comment)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = comments {
            return c.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let s = story {
            return s.title
        }
        return nil
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel.shadowOffset = CGSize.zeroSize
            header.textLabel.font = UIFont.systemFontOfSize(12)
            
            if let nav = self.navigationController as? HeadedNavigationController {
                header.alpha = nav.startingAlpha
            }
        }
    }
    
    func commentForRow(index:Int) -> Comment? {
        if let c = comments {
            return c[index]
        }
        return nil
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}