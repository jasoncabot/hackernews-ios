
//
//  ExternalURLSegue.swift
//  HackerNews
//
//  Created by Jason Cabot on 22/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class ExternalURLSegue : UIStoryboardSegue {
    
    override func perform() {
        UIApplication.shared.openURL(URL(string: "https://github.com/jasoncabot/hackernews-ios")!)
    }
}
