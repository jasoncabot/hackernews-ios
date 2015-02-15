//
//  Story.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class Story {
    var title: String
    var url: NSURL?

    init() {
        title = "Google";
        url = NSURL(string: "http://www.google.com/")
    }
}
