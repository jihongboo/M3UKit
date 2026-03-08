// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "M3UKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "M3UKit",
            targets: ["M3UKit"]
        )
    ],
    targets: [
        .target(
            name: "M3UKit"
        ),
        .testTarget(
            name: "M3UKitTests",
            dependencies: ["M3UKit"]
        )
    ]
)
