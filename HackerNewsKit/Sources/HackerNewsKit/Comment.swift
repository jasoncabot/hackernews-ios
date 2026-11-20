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

    public init(id: Int, author: String, date: Date? = nil, text: AttributedString, depth: Int, isDeleted: Bool = false) {
        self.id = id
        self.author = author
        self.date = date
        self.text = text
        self.depth = depth
        self.isDeleted = isDeleted
    }

    public var plainText: String {
        String(text.characters)
    }

    /// Whether any of the whitespace-separated keywords appears in the comment, ignoring case.
    public func matches(_ query: String) -> Bool {
        let keywords = query.split(whereSeparator: \.isWhitespace)
        guard !keywords.isEmpty else { return true }
        let text = plainText
        return keywords.contains { text.localizedCaseInsensitiveContains($0) }
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
