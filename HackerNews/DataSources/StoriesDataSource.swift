//
//  StoriesDataSource.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit
import Kanna

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
        
        var stories: [Story] = []
        if let doc = Kanna.HTML(html: data, encoding: NSUTF8StringEncoding) {
            
            let rows = doc.css(".itemlist tr")

            for idx in 0.stride(to: rows.count - 3, by: 3) {
                
                let thing = rows[idx]
                
                let anchor = thing.css("td.title a").first
                var url = anchor?["href"] ?? ""
                
                if url.hasPrefix("item?id=") {
                    url = "https://news.ycombinator.com/\(url)"
                }

                guard let title = anchor?.text else {
                    continue
                }
                
                let metaThing = rows[idx + 1]
                
                let score = (metaThing.css(".score").text?
                    .stringByReplacingOccurrencesOfString(" points", withString: "")
                    .stringByReplacingOccurrencesOfString(" point", withString: "") as NSString?)!
                    .integerValue
                let timeAgo = metaThing.css(".subtext a:nth-child(3)").text?
                    .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let author = metaThing.css(".subtext a:nth-child(2)").text?
                    .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                
                var numComments: Int = 0
                if let value = metaThing.css(".subtext a:nth-child(4)").text {
                    numComments = (value
                        .stringByReplacingOccurrencesOfString(" discuss", withString: "")
                        .stringByReplacingOccurrencesOfString(" comments", withString: "")
                        .stringByReplacingOccurrencesOfString(" comment", withString: "") as NSString)
                        .integerValue
                    
                }
                var identifier: Int = 0
                if let value = metaThing.css("a").at(1)?["href"] {
                    identifier = (value
                        .stringByReplacingOccurrencesOfString("item?id=", withString: "") as NSString)
                        .integerValue
                }

                stories.append(Story(id: identifier
                    , title: title
                    , points: score
                    , by: author ?? "unknown"
                    , timeAgo: timeAgo ?? "a little while ago"
                    , numberOfComments: numComments
                    , url: NSURL(string: url)
                    , unread: true
                    , commentsUnread: true))
                
            }
        }
        
        return stories
    }
    
    private func parseComments(data:NSData) -> [Comment] {
        var comments: [Comment] = []
        if let doc = Kanna.HTML(html: data, encoding: NSUTF8StringEncoding) {

            for thing in doc.css(".comment-tree .athing") {
                
                var indent = 0
                if let value = thing.css(".ind img").first?["width"] {
                     indent = (value as NSString).integerValue / 40
                }
                
                let comhead = thing.css(".comhead a")
                let by: String = comhead.first?.text ?? "someone"
                var when: String = "a while ago"
                if (comhead.count > 1) {
                    when = comhead.last?.text ?? when
                }

                var text = thing.css(".comment").innerHTML ?? ""

                let startOfReply = text.rangeOfString("<div class=\"reply\">")?.startIndex ?? text.endIndex
                text = (text.stringByReplacingCharactersInRange(startOfReply ..< text.endIndex, withString: "")
                    .stringByRemovingPercentEncoding?
                    .stringByReplacingOccurrencesOfString("&gt;", withString: ">")
                    .stringByReplacingOccurrencesOfString("&lt;", withString: "<")
                    .stringByReplacingOccurrencesOfString("&amp;", withString: "&")
                    .stringByReplacingOccurrencesOfString("&quot;", withString: "\"")
                    .stringByReplacingOccurrencesOfString("&apos;", withString: "'")
                    .stringByReplacingOccurrencesOfString("<[/]?([bi]|em)>", withString: "", options: .RegularExpressionSearch, range: nil)
                    .stringByReplacingOccurrencesOfString("<[/]?a[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
                    .stringByReplacingOccurrencesOfString("<[^>]+>", withString: "\n\n", options: .RegularExpressionSearch, range: nil)
                    .stringByReplacingOccurrencesOfString("\n+", withString: "\n\n", options: .RegularExpressionSearch, range: nil)
                    .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())) ?? ""

                let links = thing.css(".comment a").map({ element -> AnyObject? in
                    return (element.text == "reply") ? nil : [
                        "name": element.text!,
                        "value": element["href"]!
                    ] as NSDictionary
                }).filter({$0 != nil}).map({$0!})
                
                let data: [String: AnyObject] = [
                    "text": text,
                    "by": by,
                    "when": when,
                    "indent": indent,
                    "external_links": links
                ]

                if let comment = Comment(data: data) where !text.isEmpty {
                    comments.append(comment)
                }
            }
        }
        return comments
    }

    func endpointForPage(page: Int) -> String {
        switch type {
        case .FrontPage: return "https://news.ycombinator.com/news?p=\(page)"
        case .New: return "https://news.ycombinator.com/newest?p=\(page)"
        case .Show: return "https://news.ycombinator.com/show?p=\(page)"
        case .Ask: return "https://news.ycombinator.com/ask?p=\(page)"
        }
    }
    
    func endpointForComments(storyId: Int) -> String {
        return "https://news.ycombinator.com/item?id=\(storyId)"
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
