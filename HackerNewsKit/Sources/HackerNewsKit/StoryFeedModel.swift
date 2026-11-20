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
    /// Whether a first page has ever arrived, so an empty feed can be told apart from one still loading.
    public private(set) var hasLoaded = false

    /// Stories in the selected sort order.
    public var stories: [Story] { sortOrder.sorted(loaded) }
    public var hasMore: Bool { next != nil }

    private let client: HackerNewsClient
    private var loaded: [Story] = []
    /// Hacker News' "More" link from the last page loaded.
    private var next: URL?
    /// Bumped on every refresh so results from an older load are discarded.
    private var generation = 0
    private var firstLoad: Task<Void, Never>?

    public init(feed: Feed, client: HackerNewsClient) {
        self.feed = feed
        self.client = client
    }

    /// Starts loading the first page unless it has loaded or is already loading. Safe to call on
    /// every appearance. The load belongs to the model rather than to a view's `.task`, because
    /// SwiftUI can remove and re-add a view while a navigation transition runs; a cancelled first
    /// load used to leave the list empty and idle, showing a spinner that never went away.
    @discardableResult
    public func loadIfNeeded() -> Task<Void, Never>? {
        guard !hasLoaded else { return nil }
        if let firstLoad { return firstLoad }
        let task = Task {
            await refresh()
            firstLoad = nil
        }
        firstLoad = task
        return task
    }

    /// Reloads the feed from the first page.
    public func refresh() async {
        generation += 1
        let generation = generation
        state = .loading
        do {
            let page = try await client.firstPage(of: feed)
            guard generation == self.generation else { return }
            loaded = []
            next = nil
            append(page)
            hasLoaded = true
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
        guard state != .loading, let url = next else { return }
        let generation = generation
        state = .loading
        do {
            let page = try await client.page(at: url)
            guard generation == self.generation else { return }
            append(page)
            state = .idle
        } catch {
            guard generation == self.generation else { return }
            state = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    private func append(_ page: FeedPage) {
        // Stories move between pages as they're voted on, so a later page can repeat one
        // already shown. Repeated ids would confuse the list's diffing, so drop them.
        let seen = Set(loaded.map(\.id))
        loaded += page.stories.filter { !seen.contains($0.id) }
        // A page with no stories is the end, whatever its links say, so loading can't loop.
        next = page.stories.isEmpty ? nil : page.next
    }
}
