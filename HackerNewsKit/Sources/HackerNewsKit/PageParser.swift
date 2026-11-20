import Foundation
import Kanna

/// The page didn't look like a Hacker News page, e.g. a rate-limit notice or a captive portal.
public struct UnexpectedPage: LocalizedError {
    public var errorDescription: String? {
        "Hacker News sent back a page the app couldn't read. Try again in a moment."
    }
}

/// Extracts stories and comments from news.ycombinator.com's HTML.
///
/// Selectors follow the site's own class names (`athing`, `titleline`, `subline`, `comtr`, `commtext`),
/// which have been stable for years, rather than table positions, which are not.
enum PageParser {

    // MARK: Feeds

    static func feedPage(from data: Data, url: URL) throws -> FeedPage {
        let document = try document(from: data)
        var stories: [Story] = []
        for row in document.css("tr.athing") {
            // The row after the title holds the points, author, age and comment count.
            // Job ads have one too, just without points or an author.
            let subtext = row.at_xpath("following-sibling::tr[1]")
            if let story = story(title: row, subtext: subtext, pageURL: url, rank: stories.count + 1) {
                stories.append(story)
            }
        }
        return FeedPage(stories: stories, next: moreLink(in: document, pageURL: url))
    }

    private static func story(title row: XMLElement, subtext: XMLElement?, pageURL: URL, rank fallbackRank: Int) -> Story? {
        guard let id = row["id"].flatMap(Int.init),
              let anchor = row.at_css("span.titleline > a"),
              let title = anchor.text?.trimmed, !title.isEmpty else { return nil }

        var url = anchor["href"].flatMap { URL(string: $0, relativeTo: pageURL)?.absoluteURL }
        // Self posts link to their own discussion; the app treats those as having no article.
        if let resolved = url, resolved.host() == "news.ycombinator.com", resolved.path() == "/item" {
            url = nil
        }

        let rank = row.at_css("span.rank")?.text.flatMap(leadingInteger) ?? fallbackRank
        let site = row.at_css("span.sitestr")?.text?.trimmed

        let points = subtext?.at_css("span.score")?.text.flatMap(leadingInteger)
        let author = subtext.flatMap(userName)
        let date = subtext?.at_css("span.age")?["title"].flatMap(Self.date(fromAgeTitle:))
        let commentCount = subtext.map { Self.commentCount(in: $0, storyID: id) } ?? 0

        return Story(
            id: id,
            rank: rank,
            title: title,
            url: url,
            site: url == nil ? nil : site,
            author: author,
            points: points,
            commentCount: commentCount,
            date: date
        )
    }

    /// The "95 comments" link, which reads "discuss" when there are none.
    private static func commentCount(in subtext: XMLElement, storyID: Int) -> Int {
        let links = subtext.css("a").filter { $0["href"] == "item?id=\(storyID)" }
        for link in links.reversed() {
            guard let text = link.text?.lowercased() else { continue }
            if text.contains("comment") { return leadingInteger(text) ?? 0 }
            if text.contains("discuss") { return 0 }
        }
        return 0
    }

    // MARK: Comment threads

    static func commentPage(from data: Data, url: URL) throws -> (thread: CommentThread, next: URL?) {
        let document = try document(from: data)

        let text = document.at_css("table.fatitem div.toptext")
            .flatMap(innerHTML)
            .map(HTMLText.attributedString)
            .flatMap { $0.characters.isEmpty ? nil : $0 }

        var comments: [Comment] = []
        for row in document.xpath(XPath.commentRow) {
            if let comment = comment(from: row) {
                comments.append(comment)
            }
        }
        return (CommentThread(text: text, comments: comments), moreLink(in: document, pageURL: url))
    }

    private static func comment(from row: XMLElement) -> Comment? {
        guard let id = row["id"].flatMap(Int.init) else { return nil }

        let head = row.at_xpath(XPath.commentHead)
        let date = head?.at_xpath(XPath.age)?["title"].flatMap(Self.date(fromAgeTitle:))
        let depth = Self.depth(of: row)

        if let body = row.at_xpath(XPath.commentText), let author = head.flatMap(userName) {
            // Older markup put the reply link inside the comment text.
            for reply in body.xpath(XPath.reply) {
                reply.parent?.removeChild(reply)
            }
            return Comment(
                id: id,
                author: author,
                date: date,
                text: HTMLText.attributedString(from: innerHTML(of: body) ?? ""),
                depth: depth
            )
        }

        // Deleted and flagged comments have no text, just "[deleted]" or "[flagged]" directly inside
        // `div.comment`. Their replies are still on the page, so keep a placeholder for them to hang off.
        let placeholder = row.xpath(XPath.commentPlaceholder)
            .compactMap { $0.text?.trimmed }
            .first { !$0.isEmpty }
        return Comment(
            id: id,
            author: "",
            date: date,
            text: AttributedString(placeholder ?? "[deleted]"),
            depth: depth,
            isDeleted: true
        )
    }

    /// Hacker News indents replies with a spacer image 40 points wide per level,
    /// and newer markup also states the level in an `indent` attribute.
    private static func depth(of row: XMLElement) -> Int {
        guard let indent = row.at_xpath(XPath.indent) else { return 0 }
        if let level = indent["indent"].flatMap(Int.init) {
            return level
        }
        return (indent.at_css("img")?["width"].flatMap(Int.init) ?? 0) / 40
    }

    // MARK: Shared

    /// Queries run once per comment are written as XPath, because Kanna translates CSS
    /// selectors with regular expressions on every call, which adds up over a 2,000 comment thread.
    private enum XPath {
        static func hasClass(_ name: String) -> String {
            "contains(concat(' ', normalize-space(@class), ' '), ' \(name) ')"
        }
        static let commentRow = "//tr[\(hasClass("comtr"))]"
        static let commentHead = ".//span[\(hasClass("comhead"))]"
        static let age = ".//span[\(hasClass("age"))]"
        static let user = ".//a[starts-with(@href, 'user?id=')]"
        static let commentText = ".//*[\(hasClass("commtext"))]"
        static let reply = ".//*[\(hasClass("reply"))]"
        static let commentPlaceholder = ".//div[\(hasClass("comment"))]/text()"
        static let indent = ".//td[\(hasClass("ind"))]"
    }

    private static func document(from data: Data) throws -> HTMLDocument {
        let document = try HTML(html: data, encoding: .utf8)
        // Every real page wraps its content in this table; anything else is an error page.
        guard document.at_css("table#hnmain") != nil else { throw UnexpectedPage() }
        return document
    }

    private static func moreLink(in document: HTMLDocument, pageURL: URL) -> URL? {
        document.at_css("a.morelink")?["href"].flatMap { URL(string: $0, relativeTo: pageURL)?.absoluteURL }
    }

    private static func userName(in element: XMLElement) -> String? {
        guard let name = element.at_xpath(XPath.user)?.text?.trimmed, !name.isEmpty else { return nil }
        return name
    }

    /// Kanna's `innerHTML` strips the outer tag with a regular expression, which assumes the
    /// serialised element ends exactly with its closing tag; libxml2 can add a trailing newline.
    private static func innerHTML(of element: XMLElement) -> String? {
        guard let html = element.toHTML?.trimmingCharacters(in: .whitespacesAndNewlines),
              let open = html.firstIndex(of: ">") else { return nil }
        let afterOpen = html.index(after: open)
        let close = html.range(of: "</", options: .backwards).map(\.lowerBound) ?? html.endIndex
        return close > afterOpen ? String(html[afterOpen..<close]) : ""
    }

    /// The `title` of an age span: an ISO 8601 date in UTC without a zone, e.g. "2026-11-20T02:01:09",
    /// sometimes followed by the Unix time, e.g. "2026-11-20T02:01:09 1763604069".
    static func date(fromAgeTitle title: String) -> Date? {
        let tokens = title.split(separator: " ")
        if tokens.count > 1, let seconds = TimeInterval(tokens[1]) {
            return Date(timeIntervalSince1970: seconds)
        }
        guard let first = tokens.first else { return nil }
        let parts = first.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard parts.count >= 6 else { return nil }
        return utc.date(from: DateComponents(
            year: parts[0], month: parts[1], day: parts[2],
            hour: parts[3], minute: parts[4], second: parts[5]
        ))
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// The number a string starts with, e.g. 170 for "170 points" or 3 for "3.".
    private static func leadingInteger(_ text: String) -> Int? {
        Int(text.trimmed.prefix(while: \.isNumber))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
