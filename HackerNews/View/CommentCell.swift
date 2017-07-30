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
    var defaultTextColour: UIColor!
    var readTextColour: UIColor!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        defaultLeading = indentationConstraint.constant
        defaultTextColour = commentLabel.textColor
        readTextColour = UIColor.darkGray
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        commentLabel.textColor = defaultTextColour
        indentationConstraint.constant = defaultLeading
    }
    
    func update(with comment: Comment, store: ReadStore = ReadStore.memory) {
        userLabel.text = comment.by
        timeAgoLabel.text = comment.timeAgo
        commentLabel.text = comment.text
        commentLabel.textColor = store.hasRead(comment) ? readTextColour : defaultTextColour
        let indent = defaultLeading * CGFloat(comment.indent)
        indentationConstraint.constant = defaultLeading + indent
    }

}
