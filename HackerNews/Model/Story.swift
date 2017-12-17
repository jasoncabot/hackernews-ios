//
//  Story.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

struct Story : Equatable {
    let position: Int
    let id: Int
    let title: String
    let points: Int
    let by: String
    let timeAgo: String
    let numberOfComments: Int
    let url: URL?
    let site: String
    
    init(position: Int, id: Int, title: String, points: Int, by: String, timeAgo: String, numberOfComments: Int, url: URL?, site: String, unread: Bool, commentsUnread: Bool) {
        self.position = position
        self.id = id
        self.title = title
        self.points = points
        self.by = by
        self.timeAgo = timeAgo
        self.numberOfComments = numberOfComments
        self.url = url
        self.site = site
    }
    
    init?(data: AnyObject) {
        guard
            let position = data["position"] as? Int,
            let id = data["id"] as? Int,
            let title = data["title"] as? String,
            let points = data["score"] as? Int,
            let author = data["by"] as? String,
            let timeAgo = data["when"] as? String,
            let urlString = data["url"] as? String,
            let site = data["site"] as? String else {
                return nil
        }
        
        self.position = position
        self.id = id
        self.title = title
        self.points = points
        self.by = author
        self.timeAgo = timeAgo
        self.numberOfComments = data["comments"] as? Int ?? 0
        self.url = URL(string: urlString)
        self.site = site
    }
}

func ==(a:Story, b:Story) -> Bool {
    return a.id == b.id
}
