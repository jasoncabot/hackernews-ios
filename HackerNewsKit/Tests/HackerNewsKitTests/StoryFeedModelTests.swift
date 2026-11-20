import Foundation
import Testing
@testable import HackerNewsKit

@MainActor
struct StoryFeedModelTests {

    /// A feed split into pages of `pageSize`, each linking to the next like Hacker News does.
    private func makeClient(ids: [Int], pageSize: Int = 10) -> HackerNewsClient {
        .stub(makePages(ids: ids, pageSize: pageSize))
    }

    private func makePages(ids: [Int], pageSize: Int = 10) -> [String: String] {
        var responses: [String: String] = [:]
        let pages = stride(from: 0, to: ids.count, by: pageSize).map { Array(ids[$0..<min($0 + pageSize, ids.count)]) }
        for (index, page) in pages.enumerated() {
            let key = index == 0 ? "news" : "news?p=\(index + 1)"
            let rows = page.map { Fixture.Row(id: $0, points: $0, comments: 100 - $0) }
            var html = Fixture.feed(rows, more: index + 1 < pages.count ? "?p=\(index + 2)" : nil)
            // Ranks continue across pages on the real site.
            for (offset, _) in page.enumerated().reversed() {
                html = html.replacingOccurrences(of: "<span class=\"rank\">\(offset + 1).</span>", with: "<span class=\"rank\">\(index * pageSize + offset + 1).</span>")
            }
            responses[key] = html
        }
        return responses
    }

    @Test func refreshLoadsFirstPageWithRanks() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(101...125)))
        await model.refresh()

        #expect(model.state == .idle)
        #expect(model.stories.map(\.id) == Array(101...110))
        #expect(model.stories.map(\.rank) == Array(1...10))
        #expect(model.hasMore)
    }

    @Test func loadsFurtherPagesUntilTheEnd() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(1...25)))
        await model.refresh()
        await model.loadNextPage()
        await model.loadNextPage()

        #expect(model.stories.map(\.rank) == Array(1...25))
        #expect(!model.hasMore)

        await model.loadNextPage()
        #expect(model.stories.count == 25)
    }

    @Test func loadMoreOnlyTriggersNearTheEnd() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(1...60), pageSize: 30))
        await model.refresh()

        await model.loadMore(ifNeededAfter: model.stories[5])
        #expect(model.stories.count == 30)

        await model.loadMore(ifNeededAfter: model.stories[25])
        #expect(model.stories.count == 60)
    }

    @Test func sortOrderReordersStories() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: [3, 1, 2]))
        await model.refresh()

        #expect(model.stories.map(\.id) == [3, 1, 2])
        model.sortOrder = .points
        #expect(model.stories.map(\.id) == [3, 2, 1])
        model.sortOrder = .comments
        #expect(model.stories.map(\.id) == [1, 2, 3])
        model.sortOrder = .rank
        #expect(model.stories.map(\.id) == [3, 1, 2])
    }

    @Test func failureIsReported() async {
        let model = StoryFeedModel(feed: .front, client: .stub([:]))
        await model.refresh()

        guard case .failed = model.state else {
            Issue.record("Expected failure, got \(model.state)")
            return
        }
        #expect(model.stories.isEmpty)
    }

    @Test func refreshDiscardsAnInFlightPage() async throws {
        let gate = Gate()
        let pages = makePages(ids: Array(1...20))
        let client = HackerNewsClient { url in
            if url.query()?.contains("p=2") == true { await gate.wait() }
            return try Fixture.response(for: url, from: pages)
        }
        let model = StoryFeedModel(feed: .front, client: client)
        await model.refresh()

        let nextPage = Task { await model.loadNextPage() }
        while await gate.waiting == 0 { await Task.yield() }

        // A refresh starts while page two is still loading, then page two finishes.
        let refresh = Task { await model.refresh() }
        await refresh.value
        await gate.open()
        await nextPage.value

        #expect(model.stories.map(\.id) == Array(1...10))
    }

    @Test func dropsStoriesRepeatedOnTheNextPage() async {
        let client = HackerNewsClient.stub([
            "news": Fixture.feed([.init(id: 1), .init(id: 2)], more: "?p=2"),
            "news?p=2": Fixture.feed([.init(id: 2), .init(id: 3)]),
        ])
        let model = StoryFeedModel(feed: .front, client: client)
        await model.refresh()
        await model.loadNextPage()
        #expect(model.stories.map(\.id) == [1, 2, 3])
        #expect(!model.hasMore)
    }
}

@MainActor
struct CommentsModelTests {

    @Test func dimsOnlyCommentsReadOnAnEarlierLoad() async {
        let client = HackerNewsClient.stub([
            "item?id=1": Fixture.thread(id: 1, text: "Body", [.init(id: 10, depth: 0, html: "Hi"), .init(id: 20, depth: 0, html: "Yo")]),
        ])
        let store = ReadStore()
        let story = Story(id: 1, title: "Story", author: "op")
        let model = CommentsModel(story: story, client: client, readStore: store)

        await model.load()
        #expect(store.hasViewedComments(of: story))
        #expect(model.storyText.map { String($0.characters) } == "Body")
        #expect(!model.isPreviouslyRead(model.comments[0]))

        model.markRead(model.comments[0])
        #expect(!model.isPreviouslyRead(model.comments[0]))

        await model.load()
        #expect(model.isPreviouslyRead(model.comments[0]))
        #expect(!model.isPreviouslyRead(model.comments[1]))
    }

    @Test func filtersBySearchText() async {
        let client = HackerNewsClient.stub([
            "item?id=1": Fixture.thread(id: 1, [.init(id: 10, depth: 0, html: "Swift"), .init(id: 20, depth: 0, html: "Rust")]),
        ])
        let model = CommentsModel(story: Story(id: 1, title: "Story", author: "op"), client: client, readStore: ReadStore())
        await model.load()

        model.searchText = "swift"
        #expect(model.filteredComments.map(\.id) == [10])
        model.searchText = ""
        #expect(model.filteredComments.map(\.id) == [10, 20])
    }
}

private actor Gate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false

    var waiting: Int { continuations.count }

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func open() {
        isOpen = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}
