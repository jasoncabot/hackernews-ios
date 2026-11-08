import Foundation

public struct Comment: Identifiable, Hashable, Sendable {
    public let id: Int
    public let author: String
    public let date: Date
    public let text: AttributedString
    /// 0 for replies to the story, 1 for replies to those, and so on.
    public let depth: Int
    public let isDeleted: Bool

    public init(id: Int, author: String, date: Date, text: AttributedString, depth: Int, isDeleted: Bool = false) {
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

/// An item from the Algolia API, which returns a whole comment tree in a single request.
struct AlgoliaItem: Decodable {
    let id: Int
    let author: String?
    let text: String?
    let createdAt: TimeInterval
    let children: [AlgoliaItem]

    enum CodingKeys: String, CodingKey {
        case id, author, text, children
        case createdAt = "created_at_i"
    }

    /// Flattens the tree into display order. Top-level comments follow `ranking`
    /// (Hacker News' own ordering); deeper replies keep Algolia's chronological order.
    func flattenedComments(ranking: [Int] = []) -> [Comment] {
        let rank = Dictionary(ranking.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let topLevel = children.enumerated().sorted { lhs, rhs in
            (rank[lhs.element.id] ?? ranking.count + lhs.offset) < (rank[rhs.element.id] ?? ranking.count + rhs.offset)
        }
        var result: [Comment] = []
        for (_, child) in topLevel {
            child.append(to: &result, depth: 0)
        }
        return result
    }

    private func append(to comments: inout [Comment], depth: Int) {
        if let author, let text {
            comments.append(Comment(
                id: id,
                author: author,
                date: Date(timeIntervalSince1970: createdAt),
                text: HTMLText.attributedString(from: text),
                depth: depth
            ))
        } else if !children.isEmpty {
            // Keep a placeholder so replies to a deleted comment aren't attached to the wrong parent.
            comments.append(Comment(
                id: id,
                author: "",
                date: Date(timeIntervalSince1970: createdAt),
                text: AttributedString("[deleted]"),
                depth: depth,
                isDeleted: true
            ))
        } else {
            return
        }
        for child in children {
            child.append(to: &comments, depth: depth + 1)
        }
    }
}
