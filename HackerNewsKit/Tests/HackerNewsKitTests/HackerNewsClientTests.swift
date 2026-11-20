import Foundation
import Testing
@testable import HackerNewsKit

struct FeedParsingTests {

    private let news = URL(string: "https://news.ycombinator.com/news")!

    @Test func parsesSavedFrontPage() throws {
        let page = try PageParser.feedPage(from: Fixture.saved("news"), url: news)

        #expect(page.stories.count == 30)
        #expect(page.stories.map(\.rank) == Array(1...30))
        #expect(Set(page.stories.map(\.id)).count == 30)
        #expect(page.next == URL(string: "https://news.ycombinator.com/news?p=2"))

        let first = try #require(page.stories.first)
        #expect(first.id == 50569226)
        #expect(first.title == "OpenSSL: Buffer overflow in EVP_EncodeBlock() (CVE-2026-121481, CVSS 9.8)")
        #expect(first.url == URL(string: "https://github.com/openssl/openssl/pull/33652"))
        #expect(first.site == "github.com/openssl")
        #expect(first.points == 170)
        #expect(first.author == "JacobHenner")
        #expect(first.commentCount == 95)
        #expect(first.date == Date(timeIntervalSince1970: 1_795_140_069))
    }

    @Test func newestPageLinksToItsCursor() throws {
        let page = try PageParser.feedPage(from: Fixture.saved("newest"), url: URL(string: "https://news.ycombinator.com/newest")!)
        #expect(page.stories.count == 30)
        #expect(page.next == URL(string: "https://news.ycombinator.com/newest?next=50570716&n=31"))
    }

    @Test func askPostsHaveNoArticle() throws {
        let page = try PageParser.feedPage(from: Fixture.saved("ask"), url: URL(string: "https://news.ycombinator.com/ask")!)
        let first = try #require(page.stories.first)
        #expect(first.id == 50561571)
        #expect(first.url == nil)
        #expect(first.site == nil)
        #expect(first.link == URL(string: "https://news.ycombinator.com/item?id=50561571"))
        #expect(first.points == 25)
        #expect(page.next == nil)
    }

    @Test func jobAdsHaveNoAuthorOrPoints() throws {
        let html = Fixture.feed([.init(id: 1, points: nil, author: nil, comments: nil)])
        let story = try #require(try PageParser.feedPage(from: Data(html.utf8), url: news).stories.first)
        #expect(story.points == nil)
        #expect(story.author == nil)
        #expect(story.commentCount == 0)
        #expect(story.date == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func discussMeansNoComments() throws {
        let html = Fixture.feed([.init(id: 1, comments: 0), .init(id: 2, comments: 1), .init(id: 3, comments: 1234)])
        let stories = try PageParser.feedPage(from: Data(html.utf8), url: news).stories
        #expect(stories.map(\.commentCount) == [0, 1, 1234])
    }

    @Test func decodesEntitiesInTitles() throws {
        let html = Fixture.feed([.init(id: 1, title: "Tom &amp; Jerry&#x27;s &quot;Show&quot;")])
        let story = try #require(try PageParser.feedPage(from: Data(html.utf8), url: news).stories.first)
        #expect(story.title == #"Tom & Jerry's "Show""#)
    }

    @Test func rejectsPagesThatArentHackerNews() {
        let html = "Sorry, we're not able to serve your requests this quickly."
        #expect(throws: UnexpectedPage.self) {
            try PageParser.feedPage(from: Data(html.utf8), url: news)
        }
    }

    @Test(arguments: [
        ("2023-11-14T22:13:20", 1_700_000_000.0),
        ("2023-11-14T22:13:20 1700000001", 1_700_000_001.0),
    ])
    func parsesAges(title: String, seconds: TimeInterval) {
        #expect(PageParser.date(fromAgeTitle: title) == Date(timeIntervalSince1970: seconds))
    }
}

struct ThreadParsingTests {

    private let item = URL(string: "https://news.ycombinator.com/item?id=1")!

    @Test func parsesSavedThread() throws {
        let (thread, next) = try PageParser.commentPage(from: Fixture.saved("item"), url: item)

        #expect(thread.comments.count == 95)
        #expect(thread.text == nil)
        #expect(next == nil)
        #expect(thread.comments.prefix(4).map(\.id) == [50569705, 50570983, 50570999, 50569805])
        #expect(thread.comments.prefix(4).map(\.depth) == [0, 1, 2, 1])

        let first = thread.comments[0]
        #expect(first.author == "amluto")
        #expect(first.date == Date(timeIntervalSince1970: 1_795_144_409))
        #expect(first.plainText.hasPrefix("On a very very quick read, the bug is that EVP_EncodeBlock malfunctions"))
        #expect(first.plainText.contains("\n\nhttps://docs.openssl.org/1.0.2/man3/EVP_EncodeInit/\n\nAs a seasoned C programmer"))
        #expect(!first.plainText.contains("reply"))
        let link = try #require(first.text.runs.first { $0.link != nil })
        #expect(link.link == URL(string: "https://docs.openssl.org/1.0.2/man3/EVP_EncodeInit/"))
    }

    @Test func parsesSelfPostText() throws {
        let (thread, _) = try PageParser.commentPage(from: Fixture.saved("item-ask"), url: item)
        let text = try #require(thread.text).characters
        #expect(String(text).hasPrefix("What's going on at GitLab?\n\nThey released"))
        #expect(String(text).contains("  root@gitlab:~# cat /opt/gitlab/embedded/service/gitlab-rails/VERSION\n  19.6.0-ee\n"))
        #expect(thread.comments.count == 6)
    }

    @Test func keepsPlaceholdersForFlaggedAndDeletedComments() throws {
        let html = Fixture.thread(id: 1, [
            .init(id: 10, depth: 0, html: "First"),
            .init(id: 11, depth: 1, author: nil, html: "[flagged]"),
            .init(id: 12, depth: 2, html: "Reply to flagged"),
            .init(id: 13, depth: 0, author: nil, html: ""),
        ])
        let comments = try PageParser.commentPage(from: Data(html.utf8), url: item).thread.comments

        #expect(comments.map(\.id) == [10, 11, 12, 13])
        #expect(comments.map(\.depth) == [0, 1, 2, 0])
        #expect(comments.map(\.isDeleted) == [false, true, false, true])
        #expect(comments.map(\.plainText) == ["First", "[flagged]", "Reply to flagged", "[deleted]"])
    }

    @Test func emptySelfPostTextIsNil() throws {
        let html = Fixture.thread(id: 1, text: "", [])
        #expect(try PageParser.commentPage(from: Data(html.utf8), url: item).thread.text == nil)
    }
}

struct HackerNewsClientTests {

    @Test func followsCommentPagesWithoutRepeats() async throws {
        let client = HackerNewsClient.stub([
            "item?id=1": Fixture.thread(id: 1, text: "Body", [
                .init(id: 10, depth: 0, html: "A"),
                .init(id: 11, depth: 1, html: "B"),
            ], more: "item?id=1&p=2"),
            "item?id=1&p=2": Fixture.thread(id: 1, [
                .init(id: 11, depth: 1, html: "B"),
                .init(id: 20, depth: 0, html: "C"),
            ]),
        ])
        let thread = try await client.thread(for: Story(id: 1, title: "Story"))
        #expect(thread.comments.map(\.id) == [10, 11, 20])
        #expect(thread.text.map { String($0.characters) } == "Body")
    }

    @Test func networkErrorsPropagate() async {
        let client = HackerNewsClient.stub([:])
        await #expect(throws: URLError.self) {
            try await client.firstPage(of: .front)
        }
    }

    @Test func searchMatchesAnyKeyword() {
        let comment = Comment(id: 1, author: "a", date: .now, text: "Swift concurrency is great", depth: 0)
        #expect(comment.matches(""))
        #expect(comment.matches("SWIFT"))
        #expect(comment.matches("rust concurrency"))
        #expect(!comment.matches("rust python"))
    }
}
