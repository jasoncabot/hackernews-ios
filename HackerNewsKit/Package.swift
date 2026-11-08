// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HackerNewsKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HackerNewsKit", targets: ["HackerNewsKit"]),
    ],
    targets: [
        .target(name: "HackerNewsKit"),
        .testTarget(name: "HackerNewsKitTests", dependencies: ["HackerNewsKit"]),
    ]
)
