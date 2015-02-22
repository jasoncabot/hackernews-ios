//
//  CommentListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class CommentListViewController: UIViewController {
    
    @IBOutlet weak var commentsTableView: UITableView!
    
    var comments:Array<Comment>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        commentsTableView.reloadData()

    }
    
    func onCommentsLoaded(receivedComments:Array<Comment>) {
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