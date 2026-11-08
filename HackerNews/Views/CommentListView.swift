import HackerNewsKit
import SwiftUI

struct CommentListView: View {

    @State private var model: CommentsModel
    @State private var isSearching = false

    // Created here rather than in `.task` so the whole screen is in place on the first frame of the push.
    init(story: Story, client: HackerNewsClient, readStore: ReadStore) {
        _model = State(initialValue: CommentsModel(story: story, client: client, readStore: readStore))
    }

    var body: some View {
        let comments = model.filteredComments

        List {
            if model.searchText.isEmpty {
                Section {
                    StoryHeader(story: model.story)
                        .compactListRow()
                        .hackerNewsRowBackground()
                }
            }

            if !comments.isEmpty {
                Section(header) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment, isPreviouslyRead: model.isPreviouslyRead(comment))
                            .onAppear { model.markRead(comment) }
                            .compactListRow()
                            .hackerNewsRowBackground()
                    }
                }
            }
        }
        .listStyle(.plain)
        .hackerNewsListBackground()
        .overlay {
            if comments.isEmpty {
                emptyState
            }
        }
        .commentSearch(isPresented: $isSearching, text: $model.searchText)
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isSearching {
                ToolbarItem(placement: .primaryAction) {
                    Button("Search Comments", systemImage: "magnifyingglass") {
                        isSearching = true
                    }
                }
            }
        }
        .refreshable { await model.load() }
        .task {
            if !model.hasLoaded { await model.load() }
        }
    }

    private var header: String {
        if model.searchText.isEmpty {
            model.comments.count.counted("comment", "comments")
        } else {
            String(localized: "\(model.filteredComments.count) of \(model.comments.count) match “\(model.searchText)”")
        }
    }

    @ViewBuilder private var emptyState: some View {
        if !model.searchText.isEmpty {
            ContentUnavailableView.search(text: model.searchText)
        } else if case .failed(let message) = model.state {
            ContentUnavailableView {
                Label("Couldn't Load Comments", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await model.load() } }
            }
        } else if model.hasLoaded {
            ContentUnavailableView("No Comments Yet", systemImage: "bubble.left.and.bubble.right")
        } else {
            ProgressView()
        }
    }
}

private extension View {
    /// Only adds the search bar while searching. Having it there from the start makes the
    /// navigation bar grow as the screen is pushed, which shifts the story list underneath.
    @ViewBuilder
    func commentSearch(isPresented: Binding<Bool>, text: Binding<String>) -> some View {
        if isPresented.wrappedValue {
            searchable(text: text, isPresented: isPresented, prompt: "Search Comments")
                .onDisappear { text.wrappedValue = "" }
        } else {
            self
        }
    }
}

private struct StoryHeader: View {

    @Environment(\.openStory) private var openStory

    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.headline)

            Text("\(story.points.counted("point", "points")) by \(story.author) \(story.date, format: .relative(presentation: .named))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let text = story.text {
                Text(HTMLText.attributedString(from: text))
                    .font(.callout)
            }

            if let site = story.site {
                Button("Read on \(site)", systemImage: "safari") {
                    openStory(story)
                }
                .font(.subheadline)
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct CommentRow: View {

    let comment: Comment
    let isPreviouslyRead: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if comment.isDeleted {
                Text(comment.text)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    Text(comment.author)
                        .font(.caption.weight(.semibold))
                    Text(comment.date, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.footnote)
                    .foregroundStyle(isPreviouslyRead ? .secondary : .primary)
            }
        }
        // Deep threads would leave no room for text on a phone, so stop indenting eventually.
        .padding(.leading, CGFloat(min(comment.depth, 6)) * 12)
        .contextMenu {
            if !comment.isDeleted {
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = comment.plainText
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommentListView(story: Story(id: 1, title: "Preview", author: "pg"), client: .live, readStore: ReadStore())
    }
    .storyBrowser()
    .environment(ReadStore())
}
