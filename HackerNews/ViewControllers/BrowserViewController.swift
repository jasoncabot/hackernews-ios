//
//  BrowserViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/06/2016.
//  Copyright © 2016 Jason Cabot. All rights reserved.
//

import SafariServices

class BrowserViewController : SFSafariViewController {

    var store: ReadStore = ReadStore.memory
    var story:Story?
    var storiesSource:StoriesDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 10.0, *) {
            self.preferredControlTintColor = #colorLiteral(red: 1, green: 0.4, blue: 0, alpha: 1)
        } else {
            self.view.tintColor = #colorLiteral(red: 1, green: 0.4, blue: 0, alpha: 1)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let story = story { store.viewed(story: story) }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
