import Foundation
import Observation

/// Tracks which stories, comment threads and comments have been seen this session.
@MainActor
@Observable
public final class ReadStore {

    public private(set) var readStories: Set<Int> = []
    public private(set) var viewedCommentThreads: Set<Int> = []
    public private(set) var readComments: Set<Int> = []

    public init() {}

    public func markRead(_ story: Story) {
        readStories.insert(story.id)
    }

    public func markCommentsViewed(of story: Story) {
        viewedCommentThreads.insert(story.id)
    }

    public func markRead(_ comment: Comment) {
        readComments.insert(comment.id)
    }

    public func hasRead(_ story: Story) -> Bool {
        readStories.contains(story.id)
    }

    public func hasViewedComments(of story: Story) -> Bool {
        viewedCommentThreads.contains(story.id)
    }
}
