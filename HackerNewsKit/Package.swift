// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HackerNewsKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HackerNewsKit", targets: ["HackerNewsKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "6.1.0"),
    ],
    targets: [
        .target(name: "HackerNewsKit", dependencies: ["Kanna"]),
        .testTarget(
            name: "HackerNewsKitTests",
            dependencies: ["HackerNewsKit"],
            resources: [.copy("Pages")]
        ),
    ]
)
