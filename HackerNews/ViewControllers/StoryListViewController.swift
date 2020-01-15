//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit
import SafariServices

protocol CommentLoader: class {
    func loadComments(story: Story, completion: @escaping (([Comment]) -> Void))
}

class StoryListViewController: UIViewController, UITableViewDelegate, SFSafariViewControllerDelegate, CommentLoader {


    @IBOutlet var storiesTableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var sortButton: UIBarButtonItem!

    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var sortingLabel: UILabel!

    var storiesSource:StoriesDataSource!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = storiesSource.title
        storiesTableView.estimatedRowHeight = 72
        storiesTableView.rowHeight = UITableView.automaticDimension

        toastView.layer.cornerRadius = 15

        storiesTableView.dataSource = storiesSource

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(StoryListViewController.refreshStories(_:)), for: .valueChanged)
        storiesTableView.refreshControl = refreshControl

        showLoadingActivity(true)
        storiesSource.load(page: .first) {
            self.showLoadingActivity(false)
            self.storiesTableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        if let path = storiesTableView.indexPathForSelectedRow {
            storiesTableView.deselectRow(at: path, animated: animated)
        }

        super.viewDidAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let id = segue.identifier {
            switch id {

            case "ShowComments":
                let storyId = (sender as? ViewCommentsButton)?.key ?? 0

                guard let story = storiesSource.findStory(storyId) else {
                    return
                }

                guard let commentListViewController = segue.destination as? CommentListViewController else {
                    return
                }

                prepareComments(for: story, in: commentListViewController)

            default:
                break

            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - IBAction

    @IBAction func refreshStories(_ sender: UIRefreshControl) {

        // fade out our old stories
        UIView.animate(withDuration: 1, animations: {
            self.storiesTableView.alpha = 0.2
        })

        // load in our new ones
        storiesTableView.beginUpdates()
        storiesTableView.deleteRows(at: storiesSource.allIndexPaths, with: .none)
        storiesSource.refresh {
            sender.endRefreshing()
            self.storiesTableView.insertRows(at: self.storiesSource.allIndexPaths, with: .none)
            self.storiesTableView.flashScrollIndicators()
            self.storiesTableView.endUpdates()
            UIView.animate(withDuration: 0.25, animations: {
                self.storiesTableView.alpha = 1
            })
        }
    }

    @IBAction func changeSortOrder(_ sender: UIBarButtonItem) {
        storiesTableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        storiesTableView.flashScrollIndicators()

        storiesTableView.beginUpdates()
        let updates = storiesSource.updatedIndexPathsByChangingSortOrdering()
        updates.forEach { (from, to) in
            self.storiesTableView.moveRow(at: from as IndexPath, to: to as IndexPath)
        }

        if let visiblePaths = storiesTableView.indexPathsForVisibleRows {
            for path in visiblePaths {
                if let cell = storiesTableView.cellForRow(at: path) as? StoryCell, let story = storiesSource.storyForIndexPath(path) {
                    cell.update(with: story)
                }
            }
        }
        storiesTableView.endUpdates()

        sortingLabel.text = "\(storiesSource.sorting)"
        toastView.alpha = 0
        UIView.animate(withDuration: 0.25, animations: {
            self.toastView.alpha = 1
        }, completion: { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                UIView.animate(withDuration: 0.25, animations: {
                    self.toastView.alpha = 0
                })
            }
        })

    }

    func prepareComments(for story: Story, in viewController: CommentListViewController) {
        showNetworkIndicator(true)
        storiesSource.retrieveComments(story) { comments in
            self.showNetworkIndicator(false)
            viewController.onCommentsLoaded(story, receivedComments: comments)
            viewController.commentLoader = self

            if let path = self.storiesSource.indexPathForStory(story) {
                self.storiesTableView.reloadRows(at: [path], with: .automatic)
            }
        }
    }

    // MARK: - StoryListViewController

    fileprivate func showNetworkIndicator(_ show:Bool) {
        (UIApplication.shared.delegate as! AppDelegate).networkIndicator.displayNetworkIndicator(show)
    }

    fileprivate func showLoadingActivity(_ show:Bool) {
        showNetworkIndicator(show)

        var inset = storiesTableView.contentInset
        inset.bottom = show ? loadingView.bounds.size.height : 0
        storiesTableView.contentInset = inset

        loadingView.alpha = show ? 0 : 1
        UIView.animate(withDuration: 0.25, animations: {
            self.loadingView.alpha = show ? 1.0 : 0.0
        })
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !storiesSource.isLoading else { return }
        guard !storiesSource.hasReachedEnd else { return }
        let shouldLoadMore = indexPath.row >= storiesSource.stories.count - 10

        if !shouldLoadMore { return }

        showLoadingActivity(true)
        storiesSource.load(page: .next) {
            self.storiesTableView.reloadData()
            self.storiesTableView.flashScrollIndicators()
            self.showLoadingActivity(false)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let story = storiesSource.storyForIndexPath(storiesTableView.indexPathForSelectedRow), let url = story.url else {
            return
        }

        if UserDefaults.standard.string(forKey: LinkHandlingSegue.key) == LinkHandlingSegue.InApp {
            let browser = BrowserViewController(url: url, configuration: SFSafariViewController.Configuration())

            browser.delegate = self
            browser.story = story
            browser.storiesSource = storiesSource

            present(browser, animated: true, completion: nil)
        } else {
            ReadStore.memory.viewed(story: story)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - CommentLoader

    func loadComments(story: Story, completion: @escaping (([Comment]) -> Void)) {
        showNetworkIndicator(true)
        storiesSource.retrieveComments(story) { comments in
            self.showNetworkIndicator(false)

            completion(comments)

            if let path = self.storiesSource.indexPathForStory(story) {
                self.storiesTableView.reloadRows(at: [path], with: .automatic)
            }
        }
    }

    // MARK: - SFSafariViewControllerDelegate

    func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [UIActivity] {

        guard let browser = controller as? BrowserViewController, let story = browser.story else { return [] }

        return [ViewComments(handler: { [weak self] in
            guard let strongSelf = self else { return }

            guard let commentListViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CommentListViewController") as? CommentListViewController else {
                return
            }

            strongSelf.prepareComments(for: story, in: commentListViewController)

            let commentContainer = UINavigationController(rootViewController: commentListViewController)
            commentContainer.navigationBar.tintColor = strongSelf.navigationController?.navigationBar.tintColor
            commentContainer.navigationBar.barTintColor = strongSelf.navigationController?.navigationBar.barTintColor
            commentContainer.navigationBar.titleTextAttributes = strongSelf.navigationController?.navigationBar.titleTextAttributes
            commentContainer.navigationBar.barStyle = strongSelf.navigationController?.navigationBar.barStyle ?? .default

            if #available(iOS 13.0, *) {
                let navBarAppearance = UINavigationBarAppearance()
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.backgroundColor = #colorLiteral(red: 1, green: 0.4, blue: 0, alpha: 1)
                commentContainer.navigationBar.standardAppearance = navBarAppearance
                commentContainer.navigationBar.scrollEdgeAppearance = navBarAppearance
            }

            browser.present(commentContainer,
                            animated: true,
                            completion: nil)
        })]
    }
}

class ViewComments : UIActivity {

    private let handler: () -> ()

    init(handler: @escaping () -> ()) {
        self.handler = handler
    }

    override var activityTitle: String? { return "View Comments" }
    override var activityImage: UIImage? { return UIImage(named: "comment") }
    override var activityType: UIActivity.ActivityType? { return nil }
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    override func prepare(withActivityItems activityItems: [Any]) {

    }
    override func perform() {
        handler()
    }


}

