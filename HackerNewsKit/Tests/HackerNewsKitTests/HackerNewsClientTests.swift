import Foundation
import Testing
@testable import HackerNewsKit

struct HackerNewsClientTests {

    @Test func decodesStory() async throws {
        let client = HackerNewsClient.stub([
            "item/1.json": #"{"by":"pg","descendants":42,"id":1,"kids":[3,2],"score":120,"time":1700000000,"title":"Hello","type":"story","url":"https://www.example.com/post"}"#,
        ])
        let story = try #require(try await client.story(id: 1))
        #expect(story.title == "Hello")
        #expect(story.author == "pg")
        #expect(story.points == 120)
        #expect(story.commentCount == 42)
        #expect(story.commentIDs == [3, 2])
        #expect(story.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(story.site == "example.com")
        #expect(story.link == URL(string: "https://www.example.com/post"))
    }

    @Test func selfPostsLinkToTheirDiscussion() async throws {
        let client = HackerNewsClient.stub([
            "item/7.json": #"{"by":"someone","id":7,"score":3,"time":1700000000,"title":"Ask HN: Why?","text":"Just curious","type":"story"}"#,
        ])
        let story = try #require(try await client.story(id: 7))
        #expect(story.site == nil)
        #expect(story.text == "Just curious")
        #expect(story.link == URL(string: "https://news.ycombinator.com/item?id=7"))
    }

    @Test func storiesKeepRequestedOrderAndSkipMissingItems() async throws {
        let client = HackerNewsClient.stub([
            "item/1.json": Fixture.story(id: 1),
            "item/2.json": "null",
            "item/3.json": #"{"id":3,"deleted":true,"time":1700000000,"type":"story"}"#,
            "item/4.json": #"{"id":4,"dead":true,"by":"x","title":"Dead","time":1700000000,"type":"story"}"#,
            "item/5.json": Fixture.story(id: 5),
        ])
        let stories = try await client.stories(ids: [5, 2, 3, 4, 1])
        #expect(stories.map(\.id) == [5, 1])
    }

    @Test func networkErrorsPropagate() async {
        let client = HackerNewsClient.stub([:])
        await #expect(throws: URLError.self) {
            try await client.stories(ids: [1])
        }
    }

    @Test func flattensCommentTree() async throws {
        let client = HackerNewsClient.stub([
            "items/1": """
            {"id":1,"author":"op","created_at_i":1700000000,"children":[
              {"id":10,"author":"a","text":"First","created_at_i":1700000100,"children":[
                {"id":11,"author":"b","text":"Reply","created_at_i":1700000200,"children":[]}
              ]},
              {"id":20,"author":"c","text":"Second","created_at_i":1700000300,"children":[]},
              {"id":30,"author":null,"text":null,"created_at_i":1700000400,"children":[
                {"id":31,"author":"d","text":"Orphan","created_at_i":1700000500,"children":[]}
              ]},
              {"id":40,"author":null,"text":null,"created_at_i":1700000600,"children":[]}
            ]}
            """,
        ])
        // Hacker News ranks comment 20 first; Algolia returns them chronologically.
        let story = Story(id: 1, title: "Story", author: "op", commentIDs: [20, 10, 30])
        let comments = try await client.comments(for: story)

        #expect(comments.map(\.id) == [20, 10, 11, 30, 31])
        #expect(comments.map(\.depth) == [0, 0, 1, 0, 1])
        #expect(comments.map(\.isDeleted) == [false, false, false, true, false])
        #expect(comments[1].plainText == "First")
    }

    @Test func searchMatchesAnyKeyword() {
        let comment = Comment(id: 1, author: "a", date: .now, text: "Swift concurrency is great", depth: 0)
        #expect(comment.matches(""))
        #expect(comment.matches("SWIFT"))
        #expect(comment.matches("rust concurrency"))
        #expect(!comment.matches("rust python"))
    }
}
