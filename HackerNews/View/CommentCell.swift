//
//  CommentCell.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class CommentCell : UITableViewCell {

    @IBOutlet weak var indentationConstraint: NSLayoutConstraint!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var defaultLeading: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        defaultLeading = indentationConstraint.constant
    }
    
    func updateWithComment(comment: Comment) {
        userLabel.text = comment.by
        timeAgoLabel.text = comment.timeAgo
        commentLabel.text = comment.text
        let indent = defaultLeading * CGFloat(comment.indent)
        indentationConstraint.constant = defaultLeading + indent
    }

}
