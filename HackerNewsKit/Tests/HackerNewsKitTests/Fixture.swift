import Foundation
@testable import HackerNewsKit

enum Fixture {
    static func story(id: Int, score: Int = 1, comments: Int = 0) -> String {
        #"{"by":"user\#(id)","descendants":\#(comments),"id":\#(id),"score":\#(score),"time":1700000000,"title":"Story \#(id)","type":"story","url":"https://example.com/\#(id)"}"#
    }
}

extension HackerNewsClient {
    /// A client that answers from canned responses keyed by URL path suffix, and fails otherwise.
    static func stub(_ responses: [String: String]) -> HackerNewsClient {
        HackerNewsClient { url in
            let path = url.path()
            guard let body = responses.first(where: { path.hasSuffix("/" + $0.key) })?.value else {
                throw URLError(.fileDoesNotExist)
            }
            return Data(body.utf8)
        }
    }
}
