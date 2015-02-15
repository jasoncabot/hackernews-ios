//
//  StoryCell.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class StoryCell: UITableViewCell {

    func updateWithStory(story: Story) {
        self.textLabel?.text = story.title
    }
}
