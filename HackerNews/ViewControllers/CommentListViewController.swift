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
    
    var store = ReadStore.memory
    var story: Story?
    var comments: [Comment]?
    var dismissHandler: ((Void) -> Void)?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentsTableView.estimatedRowHeight = 68
        commentsTableView.rowHeight = UITableViewAutomaticDimension
    }

    func onCommentsLoaded(_ story:Story, receivedComments:[Comment]) {
        self.story = story
        self.comments = receivedComments

        store.viewedComments(of: story)

        commentsTableView.reloadData()
    }
    
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
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (comments ?? []).count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return story?.title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.shadowOffset = CGSize.zero
            header.textLabel!.font = UIFont.systemFont(ofSize: 12)
            
            if let nav = self.navigationController as? HeadedNavigationController {
                header.alpha = nav.startingAlpha
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard tableView.indexPathsForVisibleRows!.contains(indexPath) else { return }

        let store = ReadStore.memory

        if let comment = comment(for: indexPath.row) { store.viewed(comment: comment) }
    }
    
    func comment(for row:Int) -> Comment? {
        return comments?[row]
    }

    @IBAction func dismiss(_ sender: AnyObject) {
        dismiss(animated: true)
        dismissHandler?()
    }
    
    
}
