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
        self.subtitleLabel.text = makeTitle(story)
        self.viewCommentsButton.key = story.id
    }
    
    private func makeTitle(story:Story) -> String {
        return ""
    }
}
