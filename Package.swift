// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Resting",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Resting", targets: ["Resting"]),
    ],
    targets: [
        .target(
            name: "Resting",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "RestingTests",
            dependencies: ["Resting"]
        ),
    ]
)
