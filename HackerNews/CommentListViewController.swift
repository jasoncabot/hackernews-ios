//
//  CommentListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class CommentListViewController: UIViewController {
    
    func onCommentsLoaded(comments:Array<Comment>) {
        println("Loaded \(comments.count) comments")
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}