import Foundation
import Testing
@testable import HackerNewsKit

struct HTMLTextTests {

    @Test func plainTextIsUnchanged() {
        #expect(String(HTMLText.attributedString(from: "Hello world").characters) == "Hello world")
    }

    @Test func paragraphsBecomeBlankLines() {
        let text = HTMLText.attributedString(from: "First<p>Second<p>Third")
        #expect(String(text.characters) == "First\n\nSecond\n\nThird")
    }

    @Test(arguments: [
        ("&gt; quoted", "> quoted"),
        ("it&#x27;s", "it's"),
        ("a &amp; b", "a & b"),
        ("&quot;hi&quot;", "\"hi\""),
        ("&#x2F;path", "/path"),
        ("&#65;", "A"),
        ("AT&T", "AT&T"),
        ("&unknown;", "&unknown;"),
    ])
    func decodesEntities(html: String, expected: String) {
        #expect(String(HTMLText.attributedString(from: html).characters) == expected)
    }

    @Test func linksKeepTheirDestination() throws {
        let text = HTMLText.attributedString(
            from: #"See <a href="https:&#x2F;&#x2F;example.com&#x2F;a?b=1&amp;c=2" rel="nofollow">this</a> post"#
        )
        #expect(String(text.characters) == "See this post")
        let link = try #require(text.runs.first { $0.link != nil })
        #expect(link.link == URL(string: "https://example.com/a?b=1&c=2"))
        #expect(String(text[link.range].characters) == "this")
    }

    @Test func italicsAreEmphasised() throws {
        let text = HTMLText.attributedString(from: "a <i>really</i> good point")
        let run = try #require(text.runs.first { $0.inlinePresentationIntent != nil })
        #expect(run.inlinePresentationIntent == .emphasized)
        #expect(String(text[run.range].characters) == "really")
    }

    @Test func preformattedCodeKeepsWhitespace() throws {
        let text = HTMLText.attributedString(from: "Try:<p><pre><code>  let x = 1\n  print(x)\n</code></pre>Done")
        #expect(String(text.characters) == "Try:\n\n  let x = 1\n  print(x)\n\nDone")
        let run = try #require(text.runs.first { $0.inlinePresentationIntent == .code })
        #expect(String(text[run.range].characters) == "  let x = 1\n  print(x)\n")
    }

    @Test func unterminatedTagIsKeptAsText() {
        #expect(String(HTMLText.attributedString(from: "1 < 2").characters) == "1 < 2")
    }
}
