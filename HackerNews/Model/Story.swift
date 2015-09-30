//
//  Story.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class Story : Equatable {
    var id: Int!
    var title: String!
    var points: Int!
    var by: String!
    var timeAgo: String!
    var numberOfComments: Int!
    var url: NSURL?
    var unread: Bool
    
    init(id: Int, title: String, points: Int, by: String, timeAgo: String, numberOfComments: Int, url: NSURL?, unread: Bool) {
        self.id = id
        self.title = title
        self.points = points
        self.by = by
        self.timeAgo = timeAgo
        self.numberOfComments = numberOfComments
        self.url = url
        self.unread = unread
    }
    
    init?(data: AnyObject) {
        guard let id = data["id"] as? Int,
            let title = data["title"] as? String,
            let points = data["score"] as? Int,
            let author = data["by"] as? String,
            let timeAgo = data["when"] as? String,
            let urlString = data["url"] as? String else {
                self.unread = false
                return nil
        }
        
        self.id = id
        self.title = title
        self.points = points
        self.by = author
        self.timeAgo = timeAgo
        self.numberOfComments = data["comments"] as? Int ?? 0
        self.url = NSURL(string: urlString)
        self.unread = true
    }
}

func ==(a:Story, b:Story) -> Bool {
    return a.id == b.id
}
