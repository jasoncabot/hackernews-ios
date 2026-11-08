import Foundation
import Observation

/// The comment thread for one story.
@MainActor
@Observable
public final class CommentsModel {

    public let story: Story
    public private(set) var comments: [Comment] = []
    public private(set) var state: LoadState = .idle
    public private(set) var hasLoaded = false
    public var searchText = ""

    public var filteredComments: [Comment] {
        searchText.isEmpty ? comments : comments.filter { $0.matches(searchText) }
    }

    /// Comments that had already been seen before this load, so they can be dimmed
    /// without dimming each comment the moment it scrolls into view.
    public private(set) var previouslyRead: Set<Int> = []

    private let client: HackerNewsClient
    private let readStore: ReadStore

    public init(story: Story, client: HackerNewsClient, readStore: ReadStore) {
        self.story = story
        self.client = client
        self.readStore = readStore
    }

    public func load() async {
        state = .loading
        do {
            let comments = try await client.comments(for: story)
            previouslyRead = readStore.readComments
            self.comments = comments
            readStore.markCommentsViewed(of: story)
            hasLoaded = true
            state = .idle
        } catch {
            state = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    public func markRead(_ comment: Comment) {
        readStore.markRead(comment)
    }

    public func isPreviouslyRead(_ comment: Comment) -> Bool {
        previouslyRead.contains(comment.id)
    }
}
