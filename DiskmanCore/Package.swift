// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DiskmanCore",
    defaultLocalization: "en",
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
        .target(
            name: "DiskmanCore",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("DiskArbitration")
            ]
        ),
        .testTarget(
            name: "DiskmanCoreTests",
            dependencies: ["DiskmanCore"]
        )
    ]
)
