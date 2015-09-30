//
//  Comment.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

struct Comment {
    var id: Int
    var text: String
    var by: String
    var timeAgo: String
    var indent: Int
    var externalLinks: [Link]
    
    init?(data:AnyObject) {
        
        guard
            let id = data["id"] as? Int,
            let text = data["text"] as? String,
            let by = data["by"] as? String,
            let timeAgo = data["when"] as? String,
            let indent = data["indent"] as? Int,
            let links = data["external_links"] as? [AnyObject]
        else {
            return nil
        }
        
        self.id = id
        self.text = text
        self.by = by
        self.timeAgo = timeAgo
        self.indent = indent
        self.externalLinks = links.map() { Link(data: $0) }.filter() { $0 != nil }.map() { $0! }
    }
}