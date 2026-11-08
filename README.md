# Hacker News Reader for iOS

## Overview
After my favourite reader app stopped working I decided to write my own as every other one I tried had something missing - and it was a good opportunity to take a look at swift.

Version 2 is a rewrite in SwiftUI.

## Features
- Front Page, New, Show HN and Ask HN, loading more as you scroll
- Sort stories by position, comments or points
- Read stories and comment threads are dimmed, and comments you've already seen are greyed out when you come back
- Threaded comments with tappable links, plus search within a thread
- Open links in Safari or in an in-app browser, with a "View Comments" action in its share menu
- Works on iPhone and iPad, in light and dark mode

## Screenshots
<p>
  <img src="fastlane/screenshots/en-US/iPhone%2017%20Pro%20Max-03MainMenu_framed.png" alt="Menu" width="32%">
  <img src="fastlane/screenshots/en-US/iPhone%2017%20Pro%20Max-01StoryList_framed.png" alt="Stories" width="32%">
  <img src="fastlane/screenshots/en-US/iPhone%2017%20Pro%20Max-02CommentList_framed.png" alt="Comments" width="32%">
</p>

iPad screenshots are alongside them in [`fastlane/screenshots/en-US`](fastlane/screenshots/en-US).

## Building
Requires Xcode 26 or later. Open `HackerNews.xcodeproj` and run the `HackerNews` scheme; the app has no third-party dependencies.

The app is written in SwiftUI with Swift 6 strict concurrency and targets iOS 18. Stories come from the [official Hacker News API](https://github.com/HackerNews/API) and comment threads from the [Algolia HN Search API](https://hn.algolia.com/api), which returns a whole thread in one request.

| Folder | Contents |
|---|---|
| `HackerNews/` | The SwiftUI app |
| `HackerNewsKit/` | A Swift package with the models, API client, HTML parsing and view models |
| `HackerNewsUITests/` | The UI test that captures App Store screenshots |
| `fastlane/` | Test, screenshot and release automation, plus App Store metadata |

## Testing
The package's unit tests use Swift Testing and run on macOS without a simulator:

```sh
swift test --package-path HackerNewsKit
```

To run them together with the UI test on a simulator, use the `HackerNews` scheme in Xcode or `bundle exec fastlane test`. The UI test loads the live Front Page, so it needs a network connection.

[GitHub Actions](.github/workflows/main.yml) runs the package tests and builds the app on every push and pull request.

## Releasing
Releases use [fastlane](https://fastlane.tools), which needs Ruby 3.2 or later. Install it with Bundler, then run the lanes from the project root:

```sh
bundle install
bundle exec fastlane screenshots  # capture and frame App Store screenshots
bundle exec fastlane beta         # bump the build number and upload to TestFlight
bundle exec fastlane release      # upload to the App Store
```

`beta` and `release` both regenerate the screenshots as part of the lane, so they need an iOS simulator installed.

## License
[MIT](LICENSE)
