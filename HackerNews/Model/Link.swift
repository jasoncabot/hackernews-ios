//
//  Link.swift
//  HackerNews
//
//  Created by Jason Cabot on 20/04/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import Foundation

struct Link {
    var url: String
    var title: String
    
    init?(data: AnyObject) {
        guard let title = data["name"] as? String, let url = data["value"] as? String else {
            return nil
        }
        
        self.title = title
        self.url = url
    }
}