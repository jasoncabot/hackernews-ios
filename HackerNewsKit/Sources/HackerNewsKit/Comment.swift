import Foundation

public struct Comment: Identifiable, Hashable, Sendable {
    public let id: Int
    public let author: String
    public let date: Date?
    public let text: AttributedString
    /// 0 for replies to the story, 1 for replies to those, and so on.
    public let depth: Int
    /// Deleted and flagged comments are kept as placeholders so their replies stay under the right parent.
    public let isDeleted: Bool
    public let plainText: String
    /// `plainText` folded for searching, worked out once rather than on every keystroke.
    private let searchKey: String

    public init(id: Int, author: String, date: Date? = nil, text: AttributedString, depth: Int, isDeleted: Bool = false) {
        self.id = id
        self.author = author
        self.date = date
        self.text = text
        self.depth = depth
        self.isDeleted = isDeleted
        plainText = String(text.characters)
        searchKey = Self.fold(plainText)
    }

    /// Whether any of the whitespace-separated keywords appears in the comment,
    /// ignoring case and accents.
    public func matches(_ query: String) -> Bool {
        matches(keywords: Self.keywords(in: query))
    }

    /// Like `matches(_:)`, with the query already split by `keywords(in:)`,
    /// so a search folds it once rather than once per comment.
    public func matches(keywords: [String]) -> Bool {
        keywords.isEmpty || keywords.contains { searchKey.contains($0) }
    }

    public static func keywords(in query: String) -> [String] {
        query.split(whereSeparator: \.isWhitespace).map { fold(String($0)) }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// A story's discussion page: the post's own text, if any, and every comment in display order.
public struct CommentThread: Sendable {
    /// Body text for self posts such as Ask HN.
    public var text: AttributedString?
    public var comments: [Comment]

    public init(text: AttributedString? = nil, comments: [Comment] = []) {
        self.text = text
        self.comments = comments
    }
}

/// One page of a feed, and where the next one is.
public struct FeedPage: Sendable {
    public var stories: [Story]
    /// The page Hacker News' "More" link points to, or nil on the last page.
    public var next: URL?

    public init(stories: [Story], next: URL? = nil) {
        self.stories = stories
        self.next = next
    }
}
