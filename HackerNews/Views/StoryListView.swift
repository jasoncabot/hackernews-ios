import HackerNewsKit
import SwiftUI

struct StoryListView: View {

    @Environment(\.hackerNews) private var client
    @Environment(ReadStore.self) private var readStore
    @State private var model: StoryFeedModel
    @State private var commentsStory: Story?

    // The model is created here rather than in `.task` so the list, toolbar and title
    // are all in place on the first frame of the push instead of being swapped in mid-animation.
    init(feed: Feed, client: HackerNewsClient) {
        _model = State(initialValue: StoryFeedModel(feed: feed, client: client))
    }

    var body: some View {
        List {
            ForEach(model.stories) { story in
                StoryRow(story: story) { commentsStory = story }
                    .compactListRow()
                    .hackerNewsRowBackground()
                    .onAppear {
                        // Not `.task`: scrolling the row away shouldn't cancel loading the next page.
                        Task { await model.loadMore(ifNeededAfter: story) }
                    }
            }

            if !model.stories.isEmpty {
                footer
                    .hackerNewsRowBackground()
            }
        }
        .listStyle(.plain)
        .hackerNewsListBackground()
        .animation(.default, value: model.sortOrder)
        .overlay {
            if model.stories.isEmpty {
                switch model.state {
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't Load Stories", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") { Task { await model.refresh() } }
                    }
                case .idle, .loading:
                    ProgressView()
                }
            }
        }
        .refreshable { await model.refresh() }
        .task {
            if model.stories.isEmpty { await model.refresh() }
        }
        .navigationTitle(model.feed.title)
        .navigationDestination(item: $commentsStory) { story in
            CommentListView(story: story, client: client, readStore: readStore)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort By", selection: $model.sortOrder) {
                        ForEach(StorySortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }

    @ViewBuilder private var footer: some View {
        switch model.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
        case .failed:
            Button("Couldn't load more stories. Try again.") {
                Task { await model.loadNextPage() }
            }
            .frame(maxWidth: .infinity)
        case .idle:
            EmptyView()
        }
    }
}

struct StoryRow: View {

    @Environment(ReadStore.self) private var readStore
    @Environment(\.openStory) private var openStory

    let story: Story
    let showComments: () -> Void

    var body: some View {
        let hasRead = readStore.hasRead(story)

        HStack(spacing: 12) {
            Button {
                openStory(story)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(story.rank). \(story.title)")
                        .font(.headline)
                        .fontWeight(hasRead ? .regular : .semibold)
                        .foregroundStyle(hasRead ? .secondary : .primary)

                    Text("\(story.points.counted("point", "points")) by \(story.author) \(story.date, format: .relative(presentation: .named))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let site = story.site {
                        Text("From \(site)")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Button(action: showComments) {
                CommentCountBadge(count: story.commentCount, isUnread: !readStore.hasViewedComments(of: story))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(story.commentCount.counted("comment", "comments"))
            .accessibilityIdentifier("comments")
        }
        .contextMenu {
            Button("View Comments", systemImage: "bubble.left.and.bubble.right", action: showComments)
            ShareLink(item: story.link)
            Link(destination: story.discussionURL) {
                Label("Open Discussion in Safari", systemImage: "safari")
            }
        }
    }
}

/// The comment count drawn inside a speech bubble, the same size whatever the count
/// so the bubbles line up down the list.
private struct CommentCountBadge: View {
    let count: Int
    let isUnread: Bool

    @ScaledMetric(relativeTo: .body) private var size = 44

    var body: some View {
        Image(systemName: isUnread ? "bubble.left.fill" : "bubble.left")
            .resizable()
            .scaledToFit()
            .foregroundStyle(isUnread ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .overlay {
                Text(count, format: .number.notation(.compactName))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isUnread ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, size * 0.12)
                    // Centre on the body of the bubble rather than including its tail.
                    .offset(y: -size * 0.05)
            }
            .frame(width: size, height: size)
            .contentShape(.rect)
    }
}

#Preview {
    NavigationStack {
        StoryListView(feed: .front, client: .live)
    }
    .storyBrowser()
    .environment(ReadStore())
}

extension Int {
    /// "1 point", "2 points". Plain string formatting rather than `^[…](inflect: true)` markup,
    /// whose grammar engine is slow enough to drop frames when a page of rows first renders.
    func counted(_ singular: String, _ plural: String) -> String {
        "\(formatted()) \(self == 1 ? singular : plural)"
    }
}
