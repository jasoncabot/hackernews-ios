//
//  LinkHandlingSegue.swift
//  HackerNews
//
//  Created by Jason Cabot on 22/12/2017.
//  Copyright © 2017 Jason Cabot. All rights reserved.
//

import UIKit

class LinkHandlingSegue : UIStoryboardSegue {

    static let key = "LinkHandling"
    static let defaultValue = "External"
    static let InApp = "InApp"

    override func perform() {
        UserDefaults.standard.set(identifier, forKey: LinkHandlingSegue.key)
    }
}
