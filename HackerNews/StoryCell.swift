//
//  StoryCell.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryCell: UITableViewCell {
    
    @IBOutlet var storyTitleLabel: UILabel!;
    @IBOutlet var subtitleLabel: UILabel!;
    @IBOutlet var viewCommentsButton: ViewCommentsButton!;
    
    func updateWithStory(story: Story) {
        self.storyTitleLabel.text = story.title
        self.subtitleLabel.text = makeSubtitle(story)
        self.viewCommentsButton.setTitle("\(story.numberOfComments)", forState: .Normal)
        self.viewCommentsButton.key = String(story.id)
        
        if story.unread {
            self.storyTitleLabel.textColor = UIColor.blackColor()
            self.storyTitleLabel.font = UIFont.boldSystemFontOfSize(self.storyTitleLabel.font.pointSize)
        } else {
            self.storyTitleLabel.textColor = UIColor.darkGrayColor()
            self.storyTitleLabel.font = UIFont.systemFontOfSize(self.storyTitleLabel.font.pointSize)
        }
    }
    
    private func makeSubtitle(story:Story) -> String {
        return "\(story.points) points by \(story.by) \(story.timeAgo) ago"
    }
}
