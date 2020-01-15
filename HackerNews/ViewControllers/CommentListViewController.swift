//
//  CommentListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit


class CommentListSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var comments: [Comment] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func loadView() {
        super.loadView()
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9215686275, alpha: 1)
        table.keyboardDismissMode = .onDrag
        table.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        view = table

        tableView = table
    }

    // MARK: UITableViewDataSource

    func comment(for row:Int) -> Comment? {
        guard row < comments.count else { return nil }
        return comments[row]
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.shadowOffset = CGSize.zero
            header.textLabel!.font = UIFont.systemFont(ofSize: 12)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)

        if let comment = comment(for: indexPath.row), let commentCell = cell as? CommentCell {
            commentCell.update(with: comment)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let comment = comment(for: indexPath.row), comment.externalLinks.count > 0 else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        for externalLink in comment.externalLinks {
            alertController.addAction(UIAlertAction(title: externalLink.title, style: .default, handler: { (action:UIAlertAction) -> Void in
                if let url = URL(string: externalLink.url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
        }

        present(alertController, animated: true, completion: nil)
    }

}

class CommentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    var searchResultsController: CommentListSearchViewController!
    var searchController: UISearchController!

    weak var commentLoader: CommentLoader!

    var store = ReadStore.memory
    var story: Story?
    var comments: [Comment]?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        commentsTableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")


        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshComments(_:)), for: .valueChanged)
        commentsTableView.refreshControl = refreshControl

        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableView.automaticDimension

        searchResultsController = CommentListSearchViewController(nibName: nil, bundle: nil)

        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.barStyle = .default
        searchController.searchBar.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let nav = navigationController else { return }

        navigationItem.rightBarButtonItem = nav.isBeingPresented ? doneButton : nil

        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.setPlaceholder(textColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
        searchController.searchBar.set(textColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        searchController.searchBar.setTextField(color: #colorLiteral(red: 1, green: 0.4, blue: 0, alpha: 0.75))
        searchController.searchBar.setSearchImage(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        searchController.searchBar.setClearButton(color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.896671661))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)

        if let comment = comment(for: indexPath.row), let commentCell = cell as? CommentCell {
            commentCell.update(with: comment)
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let comment = comment(for: indexPath.row), comment.externalLinks.count > 0 else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        for externalLink in comment.externalLinks {
            alertController.addAction(UIAlertAction(title: externalLink.title, style: .default, handler: { (action:UIAlertAction) -> Void in
                if let url = URL(string: externalLink.url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (comments ?? []).count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let title = story?.title {
            let commentCount = comments?.count ?? 0
            return "\(title) - \(commentCount) \( commentCount == 1 ? "comment" : "comments" )"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.shadowOffset = CGSize.zero
            header.textLabel!.font = UIFont.systemFont(ofSize: 12)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard tableView.indexPathsForVisibleRows!.contains(indexPath) else { return }

        let store = ReadStore.memory

        if let comment = comment(for: indexPath.row) { store.viewed(comment: comment) }
    }

    // MARK: - IBAction

    private func indexPaths(_ comments: [Comment]) -> [IndexPath] {
        return comments.enumerated().map { (row, _) -> IndexPath in IndexPath(row: row, section: 0) }
    }

    @IBAction func refreshComments(_ sender: UIRefreshControl) {

        guard let story = story, let comments = comments else { return }

        let paths = indexPaths(comments)

        // fade out our old stories
        UIView.animate(withDuration: 1, animations: {
            self.commentsTableView.alpha = 0.2
        })

        // load in our new ones
        commentsTableView.beginUpdates()
        commentsTableView.deleteRows(at: paths, with: .none)
        commentLoader.loadComments(story: story) { [weak self] (receivedComments) in
            guard let strongSelf = self else { return }

            strongSelf.comments = receivedComments

            let paths = strongSelf.indexPaths(receivedComments)

            sender.endRefreshing()
            strongSelf.commentsTableView.insertRows(at: paths, with: .none)
            strongSelf.commentsTableView.flashScrollIndicators()
            strongSelf.commentsTableView.endUpdates()
            UIView.animate(withDuration: 0.25, animations: {
                strongSelf.commentsTableView.alpha = 1
            })
        }
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        guard let comments = comments else { return }
        let filter = searchController.searchBar.text
        guard let keywords = filter?.components(separatedBy: CharacterSet.whitespacesAndNewlines).map({ $0.lowercased() }) else { return }

        let matchingComments = comments.filter { comment in
            for keyword in keywords {
                if comment.text.lowercased().contains(keyword) {
                    return true
                }
            }
            return false
        }

        if let vc = searchController.searchResultsController as? CommentListSearchViewController {
            vc.title = "\(matchingComments.count) / \(comments.count) comments match '\(filter ?? "")'"
            vc.comments = matchingComments
        }
    }

    // MARK: -

    func onCommentsLoaded(_ story:Story, receivedComments:[Comment]) {
        self.story = story
        self.comments = receivedComments

        store.viewedComments(of: story)

        if isViewLoaded {
            commentsTableView.reloadData()
        }
    }
    
    func comment(for row:Int) -> Comment? {
        return comments?[row]
    }

    @IBAction func dismiss(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    
}
