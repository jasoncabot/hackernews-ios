//
//  CommentListViewController.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class CommentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

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

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshComments(_:)), for: .valueChanged)
        commentsTableView.insertSubview(refreshControl, at: 0)
        
        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let nav = navigationController else { return }

        navigationItem.rightBarButtonItem = nav.isBeingPresented ? doneButton : nil
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CommentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCellIdentifier", for: indexPath) as! CommentCell

        if let comment = comment(for: indexPath.row) {
            cell.update(with: comment)
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
                    UIApplication.shared.openURL(url)
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
