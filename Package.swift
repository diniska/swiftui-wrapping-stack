// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WrappingStack",
    platforms: [
        .iOS(.v11),
        .watchOS(.v6),
        .tvOS(.v11),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "WrappingStack",
            targets: ["WrappingStack"]),
    ],
    targets: [
        .target(
            name: "WrappingStack",
            dependencies: []),
        .testTarget(
            name: "WrappingStackTests",
            dependencies: ["WrappingStack"]),
    ]
)
