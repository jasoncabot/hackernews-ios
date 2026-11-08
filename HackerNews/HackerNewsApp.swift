//
//  HackerNewsApp.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//

import HackerNewsKit
import SwiftUI

@main
struct HackerNewsApp: App {

    @State private var readStore = ReadStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .storyBrowser()
                .environment(readStore)
        }
    }
}

extension EnvironmentValues {
    @Entry var hackerNews: HackerNewsClient = .live
}
