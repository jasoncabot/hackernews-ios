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


    var currentLeading: CGFloat!
    var defaultLeading: CGFloat!
    var defaultTextColour: UIColor!
    var readTextColour: UIColor!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        defaultLeading = indentationConstraint.constant
        defaultTextColour = commentLabel.textColor
        readTextColour = UIColor.darkGray
        currentLeading = defaultLeading
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        commentLabel.textColor = defaultTextColour
        currentLeading = defaultLeading

        setNeedsUpdateConstraints()
    }
    
    func update(with comment: Comment, store: ReadStore = ReadStore.memory) {
        userLabel.text = comment.by
        timeAgoLabel.text = comment.timeAgo
        commentLabel.text = comment.text
        commentLabel.textColor = store.hasRead(comment) ? readTextColour : defaultTextColour

        currentLeading = defaultLeading * CGFloat(comment.indent + 1)
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()

        indentationConstraint.constant = currentLeading
    }
}
