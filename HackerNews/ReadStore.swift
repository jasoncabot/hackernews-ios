//
//  ReadStore.swift
//  HackerNews
//
//  Created by Jason Cabot on 01/08/2017.
//  Copyright © 2017 Jason Cabot. All rights reserved.
//

import Foundation
import Crashlytics

class ReadStore {

    static let memory: ReadStore = ReadStore()

    private var stories: Set<Int> = []
    private var comments: Set<Int> = []
    private var allComments: Set<Comment> = []

    func viewedComments(of story: Story) {
        comments.insert(story.id)

        Answers.logCustomEvent(withName: "Comments Viewed", customAttributes: ["Story":"\(story.id)"])
    }

    func viewed(story: Story) {
        stories.insert(story.id)

        Answers.logCustomEvent(withName: "Story Viewed", customAttributes: ["Story":"\(story.id)"])
    }

    func viewed(comment: Comment) {
        allComments.insert(comment)
    }

    func hasRead(_ story: Story) -> Bool {
        return stories.contains(story.id)
    }
    
    func hasRead(_ comment: Comment) -> Bool {
        return allComments.contains(comment)
    }

    func hasReadComments(_ story: Story) -> Bool {
        return comments.contains(story.id)
    }
}
