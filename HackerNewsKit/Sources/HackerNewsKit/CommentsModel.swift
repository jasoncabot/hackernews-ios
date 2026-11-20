import Foundation
import Observation

/// The comment thread for one story.
@MainActor
@Observable
public final class CommentsModel {

    public let story: Story
    /// Body text for self posts such as Ask HN, which only comes with the thread.
    public private(set) var storyText: AttributedString?
    public private(set) var comments: [Comment] = [] {
        didSet { filter() }
    }
    public private(set) var state: LoadState = .idle
    public private(set) var hasLoaded = false
    public var searchText = "" {
        didSet { if searchText != oldValue { filter() } }
    }

    /// The comments matching `searchText`, kept up to date as it changes rather than worked
    /// out on each access: the view reads it several times per update, on every keystroke.
    public private(set) var filteredComments: [Comment] = []

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
            let thread = try await client.thread(for: story)
            previouslyRead = readStore.readComments
            storyText = thread.text
            comments = thread.comments
            readStore.markCommentsViewed(of: story)
            hasLoaded = true
            state = .idle
        } catch {
            state = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    private func filter() {
        let keywords = Comment.keywords(in: searchText)
        filteredComments = keywords.isEmpty ? comments : comments.filter { $0.matches(keywords: keywords) }
    }

    public func markRead(_ comment: Comment) {
        readStore.markRead(comment)
    }

    public func isPreviouslyRead(_ comment: Comment) -> Bool {
        previouslyRead.contains(comment.id)
    }
}
