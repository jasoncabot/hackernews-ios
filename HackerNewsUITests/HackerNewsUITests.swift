//
//  HackerNewsUITests.swift
//  HackerNewsUITests
//
//  Created by Jason Cabot on 04/12/2017.
//  Copyright © 2017 Jason Cabot. All rights reserved.
//

import XCTest

class HackerNewsUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGeneratingScreenshots() {

        let tablesQuery = XCUIApplication().tables
        snapshot("03MainMenu")
        tablesQuery.staticTexts["Front Page"].tap()
        snapshot("01StoryList")
        tablesQuery.cells.firstMatch.buttons.firstMatch.tap()
        snapshot("02CommentList")

    }
    
}
