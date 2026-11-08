import Foundation
import Testing
@testable import HackerNewsKit

@MainActor
struct StoryFeedModelTests {

    private func makeClient(ids: [Int]) -> HackerNewsClient {
        var responses = ["topstories.json": "[\(ids.map(String.init).joined(separator: ","))]"]
        for id in ids {
            responses["item/\(id).json"] = Fixture.story(id: id, score: id, comments: 100 - id)
        }
        return .stub(responses)
    }

    @Test func refreshLoadsFirstPageWithRanks() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(101...125)), pageSize: 10)
        await model.refresh()

        #expect(model.state == .idle)
        #expect(model.stories.map(\.id) == Array(101...110))
        #expect(model.stories.map(\.rank) == Array(1...10))
        #expect(model.hasMore)
    }

    @Test func loadsFurtherPagesUntilTheEnd() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(1...25)), pageSize: 10)
        await model.refresh()
        await model.loadNextPage()
        await model.loadNextPage()

        #expect(model.stories.map(\.rank) == Array(1...25))
        #expect(!model.hasMore)

        await model.loadNextPage()
        #expect(model.stories.count == 25)
    }

    @Test func loadMoreOnlyTriggersNearTheEnd() async {
        let model = StoryFeedModel(feed: .front, client: makeClient(ids: Array(1...60)), pageSize: 30)
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
        let ids = Array(1...20)
        let client = HackerNewsClient { url in
            let path = url.path()
            if path.hasSuffix("topstories.json") {
                return Data("[\(ids.map(String.init).joined(separator: ","))]".utf8)
            }
            let id = Int(url.deletingPathExtension().lastPathComponent)!
            if id > 10 { await gate.wait() }
            return Data(Fixture.story(id: id).utf8)
        }
        let model = StoryFeedModel(feed: .front, client: client, pageSize: 10)
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
}

@MainActor
struct CommentsModelTests {

    @Test func dimsOnlyCommentsReadOnAnEarlierLoad() async {
        let client = HackerNewsClient.stub([
            "items/1": #"{"id":1,"author":"op","created_at_i":0,"children":[{"id":10,"author":"a","text":"Hi","created_at_i":0,"children":[]},{"id":20,"author":"b","text":"Yo","created_at_i":0,"children":[]}]}"#,
        ])
        let store = ReadStore()
        let story = Story(id: 1, title: "Story", author: "op")
        let model = CommentsModel(story: story, client: client, readStore: store)

        await model.load()
        #expect(store.hasViewedComments(of: story))
        #expect(!model.isPreviouslyRead(model.comments[0]))

        model.markRead(model.comments[0])
        #expect(!model.isPreviouslyRead(model.comments[0]))

        await model.load()
        #expect(model.isPreviouslyRead(model.comments[0]))
        #expect(!model.isPreviouslyRead(model.comments[1]))
    }

    @Test func filtersBySearchText() async {
        let client = HackerNewsClient.stub([
            "items/1": #"{"id":1,"author":"op","created_at_i":0,"children":[{"id":10,"author":"a","text":"Swift","created_at_i":0,"children":[]},{"id":20,"author":"b","text":"Rust","created_at_i":0,"children":[]}]}"#,
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
