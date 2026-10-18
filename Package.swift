// swift-tools-version: 5.6
// V2exAPI - V2ex API 的 Swift 封装
// https://github.com/isaced/V2exAPI

import PackageDescription

let package = Package(
    name: "V2exAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "V2exAPI",
            targets: ["V2exAPI"])
    ],
    targets: [
        .target(
            name: "V2exAPI"),
        .testTarget(
            name: "V2exAPITests",
            dependencies: ["V2exAPI"]),
    ]
)
