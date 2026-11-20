import Foundation
@testable import HackerNewsKit

/// Builds pages with the same markup as news.ycombinator.com, cut down to what the parser reads.
enum Fixture {

    struct Row {
        var id: Int
        var title: String? = nil
        var href: String? = nil
        var site: String? = nil
        var points: Int? = 1
        var author: String? = "someone"
        var comments: Int? = 0
    }

    static func feed(_ rows: [Row], more: String? = nil) -> String {
        let body = rows.enumerated().map { index, row in
            let href = row.href ?? "https://example.com/\(row.id)"
            let site = row.site.map { #"<span class="sitebit comhead"> (<a href="from?site=\#($0)"><span class="sitestr">\#($0)</span></a>)</span>"# } ?? ""
            var subline = ""
            if let points = row.points { subline += #"<span class="score" id="score_\#(row.id)">\#(points) points</span> by "# }
            if let author = row.author { subline += #"<a href="user?id=\#(author)" class="hnuser">\#(author)</a> "# }
            subline += #"<span class="age" title="2023-11-14T22:13:20"><a href="item?id=\#(row.id)">2 hours ago</a></span>"#
            if let comments = row.comments {
                let label = comments == 0 ? "discuss" : "\(comments)&nbsp;comment\(comments == 1 ? "" : "s")"
                subline += #" | <a href="hide?id=\#(row.id)&amp;goto=news">hide</a> | <a href="item?id=\#(row.id)">\#(label)</a>"#
            }
            return """
            <tr class="athing submission" id="\(row.id)"><td align="right" valign="top" class="title"><span class="rank">\(index + 1).</span></td>\
            <td class="title"><span class="titleline"><a href="\(href)">\(row.title ?? "Story \(row.id)")</a>\(site)</span></td></tr>\
            <tr><td colspan="2"></td><td class="subtext"><span class="subline">\(subline)</span></td></tr>\
            <tr class="spacer" style="height:5px"></tr>
            """
        }.joined()
        let moreLink = more.map { #"<tr><td colspan="2"></td><td class='title'><a href='\#($0)' class='morelink' rel='next'>More</a></td></tr>"# } ?? ""
        return page(#"<table border="0" cellpadding="0" cellspacing="0">\#(body)\#(moreLink)</table>"#)
    }

    struct Reply {
        var id: Int
        var depth: Int
        var author: String? = "someone"
        /// HTML for the comment, or the placeholder Hacker News shows for deleted and flagged comments.
        var html: String
    }

    static func thread(id: Int, text: String = "", _ replies: [Reply], more: String? = nil) -> String {
        let rows = replies.map { reply in
            let head = reply.author.map { #"<a href="user?id=\#($0)" class="hnuser">\#($0)</a> "# } ?? ""
            let body = reply.author == nil
                ? #"<div class="comment noshow">\#(reply.html)<div class="reply"><p><font size="1"></font></div></div>"#
                : #"<div class="comment"><div class="commtext c00">\#(reply.html)</div><div class="reply"><p><font size="1"><u><a href="reply?id=\#(reply.id)">reply</a></u></font></div></div>"#
            return """
            <tr class="athing comtr" id="\(reply.id)"><td><table border="0"><tr>\
            <td class="ind" indent="\(reply.depth)"><img src="s.gif" height="1" width="\(reply.depth * 40)"></td>\
            <td class="default"><div style="margin-top:2px; margin-bottom:-10px;"><span class="comhead">\(head)\
            <span class="age" title="2023-11-14T22:13:20"><a href="item?id=\(reply.id)">1 hour ago</a></span></span></div><br>\(body)</td>\
            </tr></table></td></tr>
            """
        }.joined()
        let moreLink = more.map { #"<a href="\#($0)" class="morelink" rel="next">More</a>"# } ?? ""
        return page("""
        <table class="fatitem" border="0"><tr class="athing submission" id="\(id)"><td class="title"><span class="titleline"><a href="item?id=\(id)">Story</a></span></td></tr>\
        <tr><td colspan="2"></td><td><div class="toptext">\(text)</div></td></tr></table><br>\
        <table border="0" class="comment-tree">\(rows)</table>\(moreLink)
        """)
    }

    private static func page(_ content: String) -> String {
        #"<html lang="en" op="news"><head><title>Hacker News</title></head><body><center><table id="hnmain" border="0"><tr><td>\#(content)</td></tr></table></center></body></html>"#
    }

    static func response(for url: URL, from responses: [String: String]) throws -> Data {
        let address = url.absoluteString
        guard let body = responses.first(where: { address.hasSuffix("/" + $0.key) })?.value else {
            throw URLError(.fileDoesNotExist)
        }
        return Data(body.utf8)
    }

    /// A page saved from news.ycombinator.com.
    static func saved(_ name: String) throws -> Data {
        let url = try require(Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Pages"))
        return try Data(contentsOf: url)
    }
}

private func require<T>(_ value: T?) throws -> T {
    guard let value else { throw URLError(.fileDoesNotExist) }
    return value
}

extension HackerNewsClient {
    /// A client that answers from canned pages keyed by the end of the URL, e.g. "news" or
    /// "item?id=1", and fails otherwise.
    static func stub(_ responses: [String: String]) -> HackerNewsClient {
        HackerNewsClient { url in try Fixture.response(for: url, from: responses) }
    }
}
