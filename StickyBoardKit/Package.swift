// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "StickyBoardKit",
    platforms: [
        .iOS(.v15),     // async/await, Keychain, Swift concurrency
        .macOS(.v12)    // for future macOS client
    ],
    products: [
        .library(
            name: "StickyBoardKit",
            targets: ["StickyBoardKit"]
        ),
    ],
    targets: [
        .target(
            name: "StickyBoardKit"
        ),
        .testTarget(
            name: "StickyBoardKitTests",
            dependencies: ["StickyBoardKit"]
        ),
    ]
)
