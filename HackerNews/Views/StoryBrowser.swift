import HackerNewsKit
import SafariServices
import SwiftUI

/// Opens a story's link, either in Safari or in an in-app browser depending on the user's setting.
struct OpenStoryAction {
    fileprivate let handler: (Story) -> Void

    func callAsFunction(_ story: Story) {
        handler(story)
    }
}

extension EnvironmentValues {
    @Entry var openStory = OpenStoryAction { _ in }
}

extension View {
    /// Provides `openStory` to everything inside, presenting the in-app browser when needed.
    func storyBrowser() -> some View {
        modifier(StoryBrowserModifier())
    }
}

private struct StoryBrowserModifier: ViewModifier {

    @Environment(ReadStore.self) private var readStore
    @Environment(\.hackerNews) private var client
    @Environment(\.openURL) private var openURL
    @AppStorage(LinkHandling.key) private var linkHandling = LinkHandling.external
    // SFSafariViewController holds its delegate weakly, so keep it alive here.
    @State private var safariDelegate = SafariDelegate()

    func body(content: Content) -> some View {
        content
            .environment(\.openStory, OpenStoryAction { story in
                readStore.markRead(story)
                switch linkHandling {
                case .inApp: presentSafari(for: story)
                case .external: openURL(story.link)
                }
            })
    }

    /// Presents Safari through UIKit rather than a SwiftUI cover, so it keeps its own
    /// slide-in-from-the-right transition and can be swiped away from the left edge.
    private func presentSafari(for story: Story) {
        guard let presenter = UIApplication.shared.topViewController else {
            openURL(story.link)
            return
        }

        safariDelegate.makeComments = { [client, readStore] done in
            // Presented by UIKit from the share sheet, so the environment has to be passed along.
            UIHostingController(rootView: NavigationStack {
                CommentListView(story: story, client: client, readStore: readStore)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done", action: done)
                        }
                    }
            }
            .environment(\.hackerNews, client)
            .environment(readStore)
            // The article is already open underneath, so going back to it just closes the comments.
            .environment(\.openStory, OpenStoryAction { _ in done() }))
        }

        let safari = SFSafariViewController(url: story.link)
        safari.preferredControlTintColor = UIColor(named: "AccentColor")
        safari.delegate = safariDelegate
        presenter.present(safari, animated: true)
    }
}

private final class SafariDelegate: NSObject, SFSafariViewControllerDelegate {

    /// Builds the comments screen for the story currently open in Safari.
    var makeComments: ViewCommentsActivity.MakeViewController?

    func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [UIActivity] {
        guard let makeComments else { return [] }
        return [ViewCommentsActivity(makeViewController: makeComments)]
    }
}

private extension UIApplication {
    /// The view controller at the top of the key window's presentation stack.
    var topViewController: UIViewController? {
        let window = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// A share sheet action that shows the story's comments over the browser.
/// `UIActivity` isn't annotated for Swift concurrency, but UIKit only creates and calls it
/// on the main thread, which is what makes the unchecked conformance safe.
private nonisolated final class ViewCommentsActivity: UIActivity, @unchecked Sendable {

    typealias MakeViewController = @MainActor (_ done: @escaping @MainActor () -> Void) -> UIViewController

    private let makeViewController: MakeViewController
    private var viewController: UIViewController?

    init(makeViewController: @escaping MakeViewController) {
        self.makeViewController = makeViewController
    }

    override class var activityCategory: UIActivity.Category { .action }
    override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("com.jasoncabot.hackernews.view-comments") }
    override var activityTitle: String? { String(localized: "View Comments") }
    override var activityImage: UIImage? { UIImage(systemName: "bubble.left.and.bubble.right") }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }

    // Returning a view controller lets UIKit present it once the share sheet has gone away.
    // It holds the activity strongly so Done still works after the share sheet releases it;
    // the cycle is broken when Done is tapped.
    override var activityViewController: UIViewController? {
        MainActor.assumeIsolated {
            if viewController == nil {
                viewController = makeViewController {
                    self.activityDidFinish(true)
                    self.viewController = nil
                }
            }
            return viewController
        }
    }
}
