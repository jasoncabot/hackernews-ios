//
//  Story.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class Story {
    var id: Int = 0
    var title: String = ""
    var points: Int = 0
    var by: String = ""
    var timeAgo: String = ""
    var numberOfComments: Int = 0
    var url: NSURL?
    var unread = true
    
    init() {
    }
}
