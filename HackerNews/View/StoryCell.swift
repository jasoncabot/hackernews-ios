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
    
    func update(with story: Story, store: ReadStore = ReadStore.memory) {
        self.storyTitleLabel.text = "\(story.position). \(story.title)"
        self.subtitleLabel.text = makeSubtitle(story)
        self.viewCommentsButton.setTitle("\(story.numberOfComments)", for: UIControlState())
        self.viewCommentsButton.key = story.id
        
        if store.hasRead(story) {
            self.storyTitleLabel.textColor = UIColor.darkGray
            self.storyTitleLabel.font = UIFont.systemFont(ofSize: self.storyTitleLabel.font.pointSize)
        } else {
            self.storyTitleLabel.textColor = UIColor.black
            self.storyTitleLabel.font = UIFont.boldSystemFont(ofSize: self.storyTitleLabel.font.pointSize)
        }
        
        self.viewCommentsButton.isSelected = !store.hasReadComments(story)
    }
    
    fileprivate func makeSubtitle(_ story:Story) -> String {
        return "\(story.points) points by \(story.by) \(story.timeAgo)"
    }
}
