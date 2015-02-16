//
//  StoriesDataSource.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

enum StoryType {
    case FrontPage
    case New
    case Show
    case Ask
}

class StoriesDataSource: NSObject, UITableViewDataSource {
    
    var type:StoryType?
    var stories:Array<Story> = []

    func load(completion:dispatch_block_t?) {
        
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        stories.append(Story())
        
        if let onComplete = completion {
            onComplete()
        }
    }
    
    func title() -> String {
        if self.type != nil {
            switch (self.type!) {
            case .FrontPage:
                return "Front Page"
                
            case .New:
                return "New"
                
            case .Show:
                return "Show HN"
                
            case .Ask:
                return "Ask HN"
                
            }
        }
        
        return "Stories"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:StoryCell = tableView.dequeueReusableCellWithIdentifier("StoryCellIdentifier", forIndexPath: indexPath) as StoryCell

        
        if let story = self.findStory(indexPath.row) {
            cell.updateWithStory(story)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func findStory(index:Int) -> Story? {
        if stories.count > index {
            return stories[index]
        }
        return nil
    }
    
    func findStory(key:String) -> Story? {
        for story in stories {
            if key == story.id {
                return story
            }
        }
        return nil
    }
    
    func retrieveComments(story: Story) -> NSArray {
        return []
    }
    
}
