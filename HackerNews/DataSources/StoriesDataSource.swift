//
//  StoriesDataSource.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

enum StoryType : String {
    case FrontPage = "FrontPage"
    case New = "New"
    case Show = "Show"
    case Ask = "Ask"
}

class StoriesDataSource: NSObject, UITableViewDataSource {
    
    var type:StoryType
    var stories:[Story]
    var isLoading:Bool
    
    init(type:StoryType) {
        self.type = type
        self.stories = []
        self.isLoading = false
    }

    func load(completion:dispatch_block_t) {
        load(1, onComplete: completion)
    }

    func load(page: Int, onComplete:dispatch_block_t) {
        
        guard let url = NSURL(string: self.endpointForPage(page)) else {
            return
        }

        isLoading = true

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [unowned self] in

            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, _, _) in
                
                if let result = data {
                    let x = self.stories.count
                    self.stories += self.parseStories(result)
                    let y = self.stories.count
                    print("Stories went from \(x) to \(y)")
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.isLoading = false
                    onComplete();
                }
            }
            
            task.resume()
        }
    }
    
    func refresh(completion:dispatch_block_t) {
        stories.removeAll()
        load(completion);
    }

    private func parseStories(data:NSData) -> [Story] {
        let parsedObject: AnyObject?
        do {
            parsedObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            print("Received error \(error) parsing \(NSString(data: data, encoding: NSUTF8StringEncoding))")
            parsedObject = nil
        }
        if let storiesData = parsedObject as? [AnyObject] {
            return storiesData.map() { Story(data: $0) }.filter() { $0 != nil }.map() { $0! }
        }
        return []
    }
    
    private func parseComments(data:NSData) -> [Comment] {
        let parsedObject: AnyObject?
        do {
            parsedObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            print("Received error \(error) parsing \(NSString(data: data, encoding: NSUTF8StringEncoding))")
            parsedObject = nil
        }
        if let allCommentData = parsedObject as? [AnyObject] {
            return allCommentData.map() { Comment(data: $0) }.filter() { $0 != nil }.map() { $0! }
        }
        return []
    }
    
    func endpointForPage(page: Int) -> String {
        switch type {
        case .FrontPage: return "https://hncabot.appspot.com/fp?p=\(page)"
        case .New: return "https://hncabot.appspot.com/new?p=\(page)"
        case .Show: return "https://hncabot.appspot.com/show?p=\(page)"
        case .Ask: return "https://hncabot.appspot.com/ask?p=\(page)"
        }
    }
    
    func endpointForComments(storyId: Int) -> String {
        return "https://hncabot.appspot.com/c?id=\(storyId)"
    }
        
    var title: String {
        switch type {
        case .FrontPage: return "Front Page"
        case .New: return "New"
        case .Show: return "Show HN"
        case .Ask: return "Ask HN"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:StoryCell = tableView.dequeueReusableCellWithIdentifier("StoryCellIdentifier", forIndexPath: indexPath) as! StoryCell

        if let story = self.storyForIndexPath(indexPath) {
            cell.updateWithStory(indexPath.row + 1, story: story)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func indexPathForStory(story:Story) -> NSIndexPath? {
        if let row = stories.indexOf(story) {
            return NSIndexPath(forRow: row, inSection: 0)
        }
        return nil
    }
    
    func storyForIndexPath(indexPath:NSIndexPath?) -> Story? {
        if let path = indexPath where stories.count > path.row {
            return stories[path.row]
        }
        return nil
    }
    
    func findStory(key:Int) -> Story? {
        for story in stories {
            if key == story.id {
                return story
            }
        }
        return nil
    }
    
    func retrieveComments(story: Story, completion: ([Comment]) -> Void) -> Void {
        
        guard let url = NSURL(string: self.endpointForComments(story.id)) else {
            return
        }
        
        isLoading = true
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [unowned self] in
            
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, _, _) in
                
                let comments = data != nil ? self.parseComments(data!) : []
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.isLoading = false
                    completion(comments)
                }
            }

            task.resume()
        }
    }
    
}
