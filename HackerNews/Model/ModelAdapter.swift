//
//  JSONAdapter.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class ModelAdapter {
    func storyForData(data:NSDictionary) -> Story {
        var s = Story()
        s.id = data["id"] as Int
        s.title = data["title"] as String
        s.points = data["score"] as Int
        s.by = data["by"] as String
        s.timeAgo = data["when"] as String
        if let numComments = data["comments"] as? Int {
            s.numberOfComments = numComments
        }
        s.url = NSURL(string: data["url"] as String)
        s.unread = true
        return s
    }
    
    func commentForData(data:NSDictionary) -> Comment {
        var comment = Comment()
        comment.id = data["id"] as Int
        comment.text = data["text"] as String
        comment.by = data["by"] as String
        comment.timeAgo = data["when"] as String
        comment.indent = data["indent"] as Int
        return comment
    }
}

