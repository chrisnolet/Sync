// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Sync",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Sync",
            targets: ["Sync"]
        )
    ],
    targets: [
        .target(name: "Sync")
    ]
)
