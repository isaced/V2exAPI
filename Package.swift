// swift-tools-version: 5.9
// V2exAPI - V2ex API 的 Swift 封装
// https://github.com/isaced/V2exAPI

import PackageDescription

/// 提前采用未来 Swift 语言的特性，尽早暴露破坏性变更
let upcomingFeatures: [SwiftSetting] = [
    // 协议作为类型时必须显式写 `any`
    .enableUpcomingFeature("ExistentialAny"),
    // 多行表达式中尾随闭包的解析规则
    .enableUpcomingFeature("ForwardTrailingClosures"),
    // 更严格地推断 actor 隔离，避免隐式跨隔离
    .enableUpcomingFeature("DisableOutwardActorInference"),
]

let package = Package(
    name: "V2exAPI",
    // Apple 平台的最低版本；Linux 会忽略这一段。
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
            name: "V2exAPI",
            swiftSettings: upcomingFeatures),
        .testTarget(
            name: "V2exAPITests",
            dependencies: ["V2exAPI"],
            swiftSettings: upcomingFeatures),
    ]
)
