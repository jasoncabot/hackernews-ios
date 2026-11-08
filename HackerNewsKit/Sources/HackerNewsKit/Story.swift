import Foundation

public struct Story: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Position on Hacker News at the time the feed was loaded, starting at 1.
    public var rank: Int
    public let title: String
    public let url: URL?
    public let author: String
    public let points: Int
    public let commentCount: Int
    public let date: Date
    /// Body text for self posts such as Ask HN, as HTML.
    public let text: String?
    /// Top-level comment ids in the order Hacker News ranks them.
    public let commentIDs: [Int]

    public init(
        id: Int,
        rank: Int = 0,
        title: String,
        url: URL? = nil,
        author: String,
        points: Int = 0,
        commentCount: Int = 0,
        date: Date = .now,
        text: String? = nil,
        commentIDs: [Int] = []
    ) {
        self.id = id
        self.rank = rank
        self.title = title
        self.url = url
        self.author = author
        self.points = points
        self.commentCount = commentCount
        self.date = date
        self.text = text
        self.commentIDs = commentIDs
    }

    public var discussionURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }

    /// Where tapping the story goes: the article, or the discussion for self posts.
    public var link: URL {
        url ?? discussionURL
    }

    /// The article's domain without a leading "www.", or nil for self posts.
    public var site: String? {
        guard let host = url?.host() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

extension Story: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, url, by, score, descendants, time, text, kids, deleted, dead
    }

    /// Decodes an item from the official Firebase API.
    /// Deleted and dead items fail to decode with `ItemUnavailable`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if try container.decodeIfPresent(Bool.self, forKey: .deleted) == true
            || container.decodeIfPresent(Bool.self, forKey: .dead) == true {
            throw ItemUnavailable()
        }
        id = try container.decode(Int.self, forKey: .id)
        rank = 0
        title = try container.decode(String.self, forKey: .title)
        url = try container.decodeIfPresent(String.self, forKey: .url).flatMap(URL.init(string:))
        author = try container.decodeIfPresent(String.self, forKey: .by) ?? "unknown"
        points = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .descendants) ?? 0
        date = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: .time))
        text = try container.decodeIfPresent(String.self, forKey: .text)
        commentIDs = try container.decodeIfPresent([Int].self, forKey: .kids) ?? []
    }
}

struct ItemUnavailable: Error {}

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

    var endpoint: String {
        switch self {
        case .front: "topstories"
        case .new: "newstories"
        case .show: "showstories"
        case .ask: "askstories"
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
        case .points: stories.sorted { $0.points > $1.points }
        }
    }
}
