//
//  Story.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class Story {
    var id: String
    var title: String
    var url: NSURL?
    var unread = true

    init() {
        id = "1"
        title = "Google";
        url = NSURL(string: "http://www.google.com/")
    }
}
