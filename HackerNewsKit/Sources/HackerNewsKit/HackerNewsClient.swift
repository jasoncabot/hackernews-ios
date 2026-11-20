import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Reads feeds and comment threads from news.ycombinator.com's HTML pages, which show stories
/// and comments exactly as the site ranks them, in one request per page.
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

    static let site = URL(string: "https://news.ycombinator.com/")!

    /// Very large threads used to be split across pages; this caps how many are followed.
    private static let maxCommentPages = 20

    /// The first page of a feed.
    public func firstPage(of feed: Feed) async throws -> FeedPage {
        try await page(at: Self.site.appending(path: feed.path))
    }

    /// A page of stories, such as a previous page's `next`.
    public func page(at url: URL) async throws -> FeedPage {
        let data = try await fetch(url)
        return try PageParser.feedPage(from: data, url: url)
    }

    /// The story's text and full comment thread, in the order Hacker News shows them.
    public func thread(for story: Story) async throws -> CommentThread {
        var thread = CommentThread()
        var seen = Set<Int>()
        var next: URL? = story.discussionURL
        var pages = 0
        while let url = next, pages < Self.maxCommentPages {
            let data = try await fetch(url)
            let page = try PageParser.commentPage(from: data, url: url)
            if pages == 0 { thread.text = page.thread.text }
            thread.comments += page.thread.comments.filter { seen.insert($0.id).inserted }
            next = page.next
            pages += 1
        }
        return thread
    }
}
