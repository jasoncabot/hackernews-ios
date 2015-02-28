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
    var isLoading:Bool = false
    let adapter:ModelAdapter = ModelAdapter()

    func load(completion:dispatch_block_t) {
        load(1, onComplete: completion)
    }

    func load(page: Int, onComplete:dispatch_block_t) {
        isLoading = true
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in

            let url = NSURL(string: self.endpointForPage(page))
            
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                
                self.stories += self.parseStories(data)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.isLoading = false
                    onComplete();
                }
            }
            
            task.resume()
        })
    }

    private func parseStories(data:NSData) -> Array<Story> {
        var parseError: NSError?
        let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments,
            error:&parseError)
        var parsed:Array<Story> = []
        if let storiesData = parsedObject as? NSArray {
            for storyData in storiesData {
                if let dataDict = storyData as? NSDictionary{
                    parsed.append(adapter.storyForData(dataDict))
                }
            }
        }
        return parsed
    }
    
    private func parseComments(data:NSData) -> Array<Comment> {
        var parseError: NSError?
        let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments,
            error:&parseError)
        var parsed:Array<Comment> = []
        if let allCommentData = parsedObject as? NSArray {
            for commentData in allCommentData {
                if let dataDict = commentData as? NSDictionary{
                    parsed.append(adapter.commentForData(dataDict))
                }
            }
        }
        return parsed
    }
    
    func endpointForPage(page: Int) -> String {
        if let storyType = type {
            switch storyType {
                
            case .FrontPage:
                return "http://hncabot.appspot.com/fp?p=\(page)"
                
            case .New:
                return "http://hncabot.appspot.com/new?p=\(page)"
                
            case .Show:
                return "http://hncabot.appspot.com/show?p=\(page)"
                
            case .Ask:
                return "http://hncabot.appspot.com/ask?p=\(page)"
                
            }
        }
        return ""
    }
    
    func endpointForComments(storyId: Int) -> String {
        return "http://hncabot.appspot.com/c?id=\(storyId)"
    }
        
    func title() -> String {
        if let storyType = type {
            switch storyType {
                
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

        if let story = self.storyForIndexPath(indexPath) {
            cell.updateWithStory(indexPath.row + 1, story: story)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func indexPathForStory(story:Story) -> NSIndexPath? {
        if let row = find(stories, story) {
            return NSIndexPath(forRow: row, inSection: 0)
        }
        return nil
    }
    
    func storyForIndexPath(path:NSIndexPath) -> Story? {
        if stories.count > path.row {
            return stories[path.row]
        }
        return nil
    }
    
    func findStory(key:String) -> Story? {
        for story in stories {
            if key == String(story.id) {
                return story
            }
        }
        return nil
    }
    
    func retrieveComments(story: Story, completion: (Array<Comment>) -> Void) -> Void {
        isLoading = true

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            let url = NSURL(string: self.endpointForComments(story.id))
            
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                
                let comments = self.parseComments(data)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.isLoading = false
                    completion(comments)
                }
            }
            
            task.resume()
        })
    }
    
}
