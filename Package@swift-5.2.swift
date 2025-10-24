// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CGEventOverride",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "CGEventOverride",
            targets: ["CGEventOverride"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CGEventOverride",
            dependencies: []
        ),
    ]
)
