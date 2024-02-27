// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Sync",
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
