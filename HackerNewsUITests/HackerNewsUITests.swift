//
//  HackerNewsUITests.swift
//  HackerNewsUITests
//
//  Created by Jason Cabot on 04/12/2017.
//  Copyright © 2017 Jason Cabot. All rights reserved.
//

import XCTest

final class HackerNewsUITests: XCTestCase {

    @MainActor
    func testGeneratingScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        snapshot("03MainMenu")

        app.buttons["Front Page"].tap()
        let comments = app.buttons["comments"].firstMatch
        XCTAssertTrue(comments.waitForExistence(timeout: 15))
        snapshot("01StoryList")

        comments.tap()
        XCTAssertTrue(app.navigationBars["Comments"].waitForExistence(timeout: 5))
        snapshot("02CommentList")
    }
}
