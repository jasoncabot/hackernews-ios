//
//  StoriesDataSource.swift
//  HackerNews
//
//  Created by Jason Cabot on 15/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit
import Kanna
import Crashlytics

enum PageType {
    case first
    case next
}

enum StoryType : String {
    case front = "FrontPage"
    case new = "New"
    case show = "Show"
    case ask = "Ask"

    func endpoint(for page: Int) -> String {
        switch self {
        case .front: return "https://news.ycombinator.com/news?p=\(page)"
        case .new: return "https://news.ycombinator.com/newest?p=\(page)"
        case .show: return "https://news.ycombinator.com/show?p=\(page)"
        case .ask: return "https://news.ycombinator.com/ask?p=\(page)"
        }
    }

    var title: String {
        switch self {
        case .front: return "Front Page"
        case .new: return "New"
        case .show: return "Show HN"
        case .ask: return "Ask HN"
        }
    }
}

enum StorySortOrder {
    case position
    case comments
    case points
}

extension Story {
    var commentEndpoint: String {
        return "https://news.ycombinator.com/item?id=\(id)"
    }
}

class StoriesDataSource: NSObject, UITableViewDataSource {

    let storyQueue = DispatchQueue(label: "com.jasoncabot.hn.stories", attributes: .concurrent)
    let commentQueue = DispatchQueue(label: "com.jasoncabot.hn.comments", attributes: .concurrent)

    var page: Int = 1
    var type: StoryType
    var sorting: StorySortOrder = .position
    var stories: [Story]
    var isLoading: Bool

    init(type:StoryType) {
        self.type = type
        self.stories = []
        self.isLoading = false
    }

    var title: String {
        return type.title
    }

    func load(page: PageType, completionHandler:@escaping ()->()) {

        storyQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }

            switch page {
            case .first:
                strongSelf.page = 1
                strongSelf.stories.removeAll()
            case .next:
                strongSelf.page = strongSelf.page + 1
            }

            Answers.logCustomEvent(withName: "Page Loaded", customAttributes: ["Page":"\(page)"])

            guard let url = URL(string: strongSelf.type.endpoint(for: strongSelf.page)) else {
                return
            }

            strongSelf.isLoading = true

            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                guard let strongSelf = self else { return }

                strongSelf.storyQueue.async(flags: .barrier) {

                    if let result = data {
                        strongSelf.stories += strongSelf.parseStories(result)
                    }

                    DispatchQueue.main.async {
                        strongSelf.isLoading = false
                        completionHandler();
                    }
                }
            })

            task.resume()
        }
    }

    func refresh(_ completionHandler:@escaping ()->()) {
        load(page: .first, completionHandler: completionHandler)
    }

    func updatedIndexPathsByChangingSortOrdering() -> [(IndexPath, IndexPath)] {

        switch sorting {
        case .position: sorting = .comments
        case .comments: sorting = .points
        case .points: sorting = .position
        }

        var updates: [(IndexPath, IndexPath)] = []

        storyQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }

            let sortedStories: [Story]
            switch strongSelf.sorting {
            case .position: sortedStories = strongSelf.stories.sorted { (a, b) in a.position <= b.position }
            case .comments: sortedStories =  strongSelf.stories.sorted { (a, b) in a.numberOfComments > b.numberOfComments }
            case .points: sortedStories = strongSelf.stories.sorted { (a, b) in a.points > b.points }
            }

            updates = strongSelf.stories.enumerated().map { (index, story) in
                return (
                    IndexPath(row: index, section: 0),
                    IndexPath(row: sortedStories.index(of: story)!, section: 0)
                )
            }

            strongSelf.stories = sortedStories
        }

        return updates
    }

    fileprivate func parseStories(_ data:Data) -> [Story] {

        guard let doc = Kanna.HTML(html: data, encoding: .utf8) else { return [] }


        let rows = doc.css(".itemlist tr")
        var position = self.stories.endIndex

        let stories: [Story] = stride(from: 0, to: rows.count - 3, by: 3).map({ idx in
            let thing = rows[idx]

            let anchor = thing.css("td.title a").first
            var url = anchor?["href"] ?? ""

            if url.hasPrefix("item?id=") {
                url = "https://news.ycombinator.com/\(url)"
            }

            let site = thing.css(".sitestr").first?.text ?? ""

            guard let title = anchor?.text else {
                return nil
            }

            let metaThing = rows[idx + 1]

            let score = Int((metaThing.css(".score").first?.text ?? "0")
                .replacingOccurrences(of: " points", with: "")
                .replacingOccurrences(of: " point", with: ""))!
            let timeAgo = metaThing.css(".subtext a:nth-child(1)").first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let author = metaThing.css(".subtext a:nth-child(2)").first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)


            var numComments: Int = 0
            if let value = metaThing.css(".subtext a").reversed().first?.text {
                numComments = (value
                    .replacingOccurrences(of: " discuss", with: "")
                    .replacingOccurrences(of: " comments", with: "")
                    .replacingOccurrences(of: " comment", with: "") as NSString)
                    .integerValue

            }
            var identifier: Int = 0

            if let value = metaThing.css("a")[1]["href"] {
                identifier = Int(value.replacingOccurrences(of: "item?id=", with: "")) ?? 0
            }

            position += 1

            return Story(position: position
                , id: identifier
                , title: title
                , points: score
                , by: author ?? "unknown"
                , timeAgo: timeAgo ?? "a little while ago"
                , numberOfComments: numComments
                , url: URL(string: url)
                , site: site
                , unread: true
                , commentsUnread: true)
        }).filter { $0 != nil }.map { $0! }

        return stories
    }

    fileprivate func parseComments(_ data:Data) -> [Comment] {
        var comments: [Comment] = []
        if let doc = Kanna.HTML(html: data, encoding: String.Encoding.utf8) {

            for thing in doc.css(".comment-tree .athing") {

                var indent = 0
                if let value = thing.css(".ind img").first?["width"] {
                    indent = (value as NSString).integerValue / 40
                }

                let comhead = thing.css(".comhead a")
                let by: String = comhead.first?.text ?? "someone"
                var when: String = "a while ago"
                if (comhead.count > 1) {
                    when = comhead[comhead.count - 1].text ?? when
                }

                var text = thing.css(".comment").first?.innerHTML ?? ""

                let startOfReply = text.range(of: "<div class=\"reply\">")?.lowerBound ?? text.endIndex
                text = (text.replacingCharacters(in: startOfReply ..< text.endIndex, with: "")
                    .removingPercentEncoding?
                    .replacingOccurrences(of: "<[/]?([bi]|em|pre|code)>", with: "", options: .regularExpression, range: nil)
                    .replacingOccurrences(of: "<[/]?a[^>]*>", with: "", options: .regularExpression, range: nil)
                    .replacingOccurrences(of: "<[^>]+>", with: "\n\n", options: .regularExpression, range: nil)
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")
                    .replacingOccurrences(of: "\n+", with: "\n\n", options: .regularExpression, range: nil)
                    .trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""

                let links = thing.css(".comment a").map({ element -> AnyObject? in
                    return (element.text == "reply") ? nil : [
                        "name": element.text!,
                        "value": element["href"]!
                        ] as NSDictionary
                }).filter({$0 != nil}).map({$0!})

                let data: [String: Any] = [
                    "text": text,
                    "by": by,
                    "when": when,
                    "indent": indent,
                    "external_links": links
                ]

                if let comment = Comment(data: data as AnyObject), !text.isEmpty {
                    comments.append(comment)
                }
            }
        }
        return comments
    }

    func indexPathForStory(_ story:Story) -> IndexPath? {
        var path: IndexPath?
        storyQueue.sync {
            if let row = stories.index(of: story) {
                path = IndexPath(row: row, section: 0)
            }
        }
        return path
    }

    var allIndexPaths: [IndexPath] {
        var paths: [IndexPath] = []
        storyQueue.sync {
            paths = stories.enumerated().map { (offset, _) in IndexPath(row: offset, section: 0) }
        }
        return paths
    }

    func storyForIndexPath(_ indexPath:IndexPath?) -> Story? {
        var story: Story?
        storyQueue.sync {
            if let path = indexPath, stories.count > path.row {
                story = stories[path.row]
            }
        }
        return story
    }

    func findStory(_ key:Int) -> Story? {
        var story: Story?
        storyQueue.sync {
            story = stories.first(where: { $0.id == key })
        }
        return story
    }

    func retrieveComments(_ story: Story, completionHandler: @escaping ([Comment]) -> Void) -> Void {

        guard let url = URL(string: story.commentEndpoint) else {
            return
        }

        commentQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return; }
            
            strongSelf.isLoading = true
            
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                
                let comments = data != nil ? strongSelf.parseComments(data!) : []
                
                DispatchQueue.main.async {
                    strongSelf.isLoading = false
                    completionHandler(comments)
                }
            })
            
            task.resume()
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:StoryCell = tableView.dequeueReusableCell(withIdentifier: "StoryCellIdentifier", for: indexPath) as! StoryCell

        if let story = storyForIndexPath(indexPath) {
            cell.update(with: story)
        }

        return cell;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int = 0
        storyQueue.sync {
            count = stories.count
        }
        return count
    }
    
}
