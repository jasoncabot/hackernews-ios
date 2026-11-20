import HackerNewsKit
import SwiftUI

struct RootView: View {

    @Environment(\.hackerNews) private var client
    @Environment(ReadStore.self) private var readStore
    @State private var selection: Feed?
    /// The feed in the detail column. Unlike `selection` it isn't cleared when the collapsed
    /// split view pops back to the sidebar, so the story list stays put for the whole pop
    /// instead of being swapped for "Choose a Feed" as it slides away.
    @State private var shownFeed: Feed?
    /// Comment threads pushed on top of the story list.
    @State private var path: [Story] = []
    @AppStorage(LinkHandling.key) private var linkHandling = LinkHandling.external

    var body: some View {
        NavigationSplitView {
            List(selection: feedSelection) {
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
            NavigationStack(path: $path) {
                Group {
                    if let shownFeed {
                        StoryListView(feed: shownFeed, client: client) { path.append($0) }
                            .id(shownFeed)
                    } else {
                        ContentUnavailableView("Choose a Feed", systemImage: "newspaper")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.hnBackground))
                    }
                }
                // Registered on the stack's root, outside the `.id` above, so it's the same
                // destination whichever feed is showing and survives switching feeds.
                .navigationDestination(for: Story.self) { story in
                    CommentListView(story: story, client: client, readStore: readStore)
                }
            }
        }
    }

    /// Updates the shown feed and the comments on top of it in the same transaction as the
    /// selection, so a feed never appears with another feed's comments still pushed over it.
    private var feedSelection: Binding<Feed?> {
        Binding {
            selection
        } set: { feed in
            selection = feed
            guard let feed, feed != shownFeed else { return }
            path.removeAll()
            shownFeed = feed
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
