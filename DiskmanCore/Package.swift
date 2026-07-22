// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DiskmanCore",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .library(
            name: "DiskmanCore",
            targets: ["DiskmanCore"]
        )
    ],
    targets: [
        .target(name: "DiskmanCore"),
        .testTarget(
            name: "DiskmanCoreTests",
            dependencies: ["DiskmanCore"]
        )
    ]
)
