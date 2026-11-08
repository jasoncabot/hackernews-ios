import Foundation

/// Talks to the official Hacker News Firebase API for stories and to the Algolia API
/// for comment threads, which returns a whole thread in one request instead of one per comment.
public struct HackerNewsClient: Sendable {

    public typealias Fetch = @Sendable (URL) async throws -> Data

    private let fetch: Fetch

    public init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    public static let live = HackerNewsClient { url in
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static let firebase = URL(string: "https://hacker-news.firebaseio.com/v0/")!
    private static let algolia = URL(string: "https://hn.algolia.com/api/v1/")!

    /// Story ids for a feed, in the order they appear on the site.
    public func storyIDs(for feed: Feed) async throws -> [Int] {
        let data = try await fetch(Self.firebase.appending(path: "\(feed.endpoint).json"))
        return try JSONDecoder().decode([Int].self, from: data)
    }

    /// Fetches stories concurrently, returning them in the order of `ids`.
    /// Deleted and dead stories are left out.
    public func stories(ids: [Int]) async throws -> [Story] {
        try await withThrowingTaskGroup(of: (Int, Story?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { (index, try await story(id: id)) }
            }
            var stories = [Story?](repeating: nil, count: ids.count)
            for try await (index, story) in group {
                stories[index] = story
            }
            return stories.compactMap { $0 }
        }
    }

    public func story(id: Int) async throws -> Story? {
        let data = try await fetch(Self.firebase.appending(path: "item/\(id).json"))
        return try? JSONDecoder().decode(Story?.self, from: data)
    }

    /// The story's full comment thread, flattened into display order.
    public func comments(for story: Story) async throws -> [Comment] {
        let data = try await fetch(Self.algolia.appending(path: "items/\(story.id)"))
        let item = try JSONDecoder().decode(AlgoliaItem.self, from: data)
        return item.flattenedComments(ranking: story.commentIDs)
    }
}
