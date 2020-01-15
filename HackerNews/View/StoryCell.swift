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
    @IBOutlet var siteLabel: UILabel!;
    @IBOutlet var viewCommentsButton: ViewCommentsButton!;
    
    func update(with story: Story, store: ReadStore = ReadStore.memory) {
        storyTitleLabel.text = "\(story.position). \(story.title)"
        subtitleLabel.text = "\(story.points) points by \(story.by) \(story.timeAgo)"
        viewCommentsButton.setTitle("\(story.numberOfComments)", for: .normal)
        viewCommentsButton.key = story.id
        if !story.site.isEmpty {
            siteLabel.text = "From \(story.site)"
        } else {
            siteLabel.text = ""
        }

        if store.hasRead(story) {
            storyTitleLabel.textColor = UIColor.darkGray
            storyTitleLabel.font = UIFont.systemFont(ofSize: storyTitleLabel.font.pointSize)
        } else {
            storyTitleLabel.textColor = UIColor.black
            storyTitleLabel.font = UIFont.boldSystemFont(ofSize: storyTitleLabel.font.pointSize)
        }
        
        viewCommentsButton.isSelected = !store.hasReadComments(story)

        setNeedsUpdateConstraints()
    }
}
