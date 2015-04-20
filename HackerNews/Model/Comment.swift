//
//  Comment.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

class Comment {
    var id: Int = 0
    var text: String = ""
    var by: String = ""
    var timeAgo: String = ""
    var indent: Int = 0
    var externalLinks: Array<Link> = []

    init() {
    }
}