import Foundation
import Observation

public enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case failed(String)
}

extension Error {
    /// True for task cancellation, e.g. when a view disappears mid-load or a refresh is interrupted.
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}

/// A paged list of stories for one feed.
@MainActor
@Observable
public final class StoryFeedModel {

    public let feed: Feed
    public var sortOrder: StorySortOrder = .rank
    public private(set) var state: LoadState = .idle

    /// Stories in the selected sort order.
    public var stories: [Story] { sortOrder.sorted(loaded) }
    public var hasMore: Bool { loadedIDCount < ids.count }

    private let client: HackerNewsClient
    private let pageSize: Int
    private var loaded: [Story] = []
    private var ids: [Int] = []
    private var loadedIDCount = 0
    /// Bumped on every refresh so results from an older load are discarded.
    private var generation = 0

    public init(feed: Feed, client: HackerNewsClient, pageSize: Int = 30) {
        self.feed = feed
        self.client = client
        self.pageSize = pageSize
    }

    /// Reloads the feed from the first page.
    public func refresh() async {
        generation += 1
        let generation = generation
        state = .loading
        do {
            let ids = try await client.storyIDs(for: feed)
            let firstPage = try await page(of: ids, from: 0)
            guard generation == self.generation else { return }
            self.ids = ids
            loaded = firstPage
            loadedIDCount = min(pageSize, ids.count)
            state = .idle
        } catch {
            guard generation == self.generation else { return }
            state = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    /// Loads the next page when `story` is close to the end of what's loaded.
    public func loadMore(ifNeededAfter story: Story) async {
        guard state != .loading, hasMore,
              let index = stories.firstIndex(of: story),
              index >= stories.count - 10 else { return }
        await loadNextPage()
    }

    public func loadNextPage() async {
        guard state != .loading, hasMore else { return }
        let generation = generation
        let start = loadedIDCount
        state = .loading
        do {
            let next = try await page(of: ids, from: start)
            guard generation == self.generation else { return }
            loaded += next
            loadedIDCount = min(start + pageSize, ids.count)
            state = .idle
        } catch {
            guard generation == self.generation else { return }
            state = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    private func page(of ids: [Int], from start: Int) async throws -> [Story] {
        let end = min(start + pageSize, ids.count)
        guard start < end else { return [] }
        let rankByID = Dictionary(uniqueKeysWithValues: ids[start..<end].enumerated().map { ($1, start + $0 + 1) })
        return try await client.stories(ids: Array(ids[start..<end])).map { story in
            var story = story
            story.rank = rankByID[story.id] ?? 0
            return story
        }
    }
}
