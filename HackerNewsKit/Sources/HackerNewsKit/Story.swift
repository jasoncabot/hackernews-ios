import Foundation

public struct Story: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Position on Hacker News at the time the feed was loaded, starting at 1.
    public var rank: Int
    public let title: String
    /// The article, or nil for self posts such as Ask HN.
    public let url: URL?
    /// The site Hacker News shows next to the title, e.g. "github.com/apple". Nil for self posts.
    public let site: String?
    /// Nil for job ads, which have no submitter.
    public let author: String?
    /// Nil for job ads, which can't be voted on.
    public let points: Int?
    public let commentCount: Int
    public let date: Date?

    public init(
        id: Int,
        rank: Int = 0,
        title: String,
        url: URL? = nil,
        site: String? = nil,
        author: String? = nil,
        points: Int? = nil,
        commentCount: Int = 0,
        date: Date? = nil
    ) {
        self.id = id
        self.rank = rank
        self.title = title
        self.url = url
        self.site = site ?? url.flatMap(Self.domain)
        self.author = author
        self.points = points
        self.commentCount = commentCount
        self.date = date
    }

    public var discussionURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }

    /// Where tapping the story goes: the article, or the discussion for self posts.
    public var link: URL {
        url ?? discussionURL
    }

    private static func domain(of url: URL) -> String? {
        guard let host = url.host() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

public enum Feed: String, CaseIterable, Identifiable, Hashable, Sendable {
    case front = "FrontPage"
    case new = "New"
    case show = "Show"
    case ask = "Ask"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .front: "Front Page"
        case .new: "New"
        case .show: "Show HN"
        case .ask: "Ask HN"
        }
    }

    public var systemImage: String {
        switch self {
        case .front: "newspaper"
        case .new: "clock"
        case .show: "sparkles"
        case .ask: "questionmark.bubble"
        }
    }

    /// The page on news.ycombinator.com that lists this feed.
    var path: String {
        switch self {
        case .front: "news"
        case .new: "newest"
        case .show: "show"
        case .ask: "ask"
        }
    }
}

public enum StorySortOrder: String, CaseIterable, Identifiable, Sendable {
    case rank, comments, points

    public var id: Self { self }

    public var title: String {
        switch self {
        case .rank: "Position"
        case .comments: "Comments"
        case .points: "Points"
        }
    }

    func sorted(_ stories: [Story]) -> [Story] {
        switch self {
        case .rank: stories.sorted { $0.rank < $1.rank }
        case .comments: stories.sorted { $0.commentCount > $1.commentCount }
        case .points: stories.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
        }
    }
}
