import HackerNewsKit
import SwiftUI

struct RootView: View {

    @Environment(\.hackerNews) private var client
    @State private var selection: Feed?
    @AppStorage(LinkHandling.key) private var linkHandling = LinkHandling.external

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Stories") {
                    ForEach(Feed.allCases) { feed in
                        NavigationLink(value: feed) {
                            Label(feed.title, systemImage: feed.systemImage)
                        }
                    }
                }

                Section("Settings") {
                    Picker("Open Links", selection: $linkHandling) {
                        ForEach(LinkHandling.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                Section {
                    Link(destination: URL(string: "https://github.com/jasoncabot/hackernews-ios")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .hackerNewsListBackground()
            .navigationTitle("Hacker News")
        } detail: {
            NavigationStack {
                if let selection {
                    StoryListView(feed: selection, client: client)
                        .id(selection)
                } else {
                    ContentUnavailableView("Choose a Feed", systemImage: "newspaper")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.hnBackground))
                }
            }
        }
    }
}

enum LinkHandling: String, CaseIterable, Identifiable {
    // Raw values match what the UIKit version stored, so existing preferences carry over.
    case external = "External"
    case inApp = "InApp"

    static let key = "LinkHandling"

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .external: "Safari"
        case .inApp: "In App"
        }
    }
}

#Preview {
    RootView()
        .storyBrowser()
        .environment(ReadStore())
}
