# V2exAPI
[![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)](https://github.com/isaced/V2exAPI)
[![CocoaPods](https://img.shields.io/cocoapods/v/V2exAPI.svg?style=for-the-badge)](https://cocoapods.org/pods/V2exAPI)
[![Carthage](https://img.shields.io/badge/-Carthage-5C5543?style=for-the-badge)](https://github.com/Carthage/Carthage)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/isaced/V2exAPI)
[![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)](https://github.com/isaced/V2exAPI)

A V2ex API wrapper for iOS/macOS, built with Swift.

## Features

- [x] SPM(Swift Package Manager) Support
- [x] Swift async/await Support
- [x] V2ex API V1 100%
- [x] V2ex API V2 100%

## API Support

### V1

| 接口   | 路径                   | 进度  |
|------|-------------------------|-----|
| Hottest topic | /api/topics/hot.json    | &#9745; |
| Latest Topics | /api/topics/latest.json | &#9745; |
| Node list | /api/nodes/show.json    | &#9745; |
| Profile info | /api/members/show.json  | &#9745; |

### V2

| 接口            | 路径                           | 进度 |
|----------------------|--------------------------------|---------|
| Get the latest notifications       | notifications                  | &#9745; |
| Delete the specified notification       | notifications/:notification_id | &#9745; |
| Get your own Profile   | member                         | &#9745; |
| Get the currently used token   | token                          | &#9745; |
| get the specified node         | nodes/:node_name               | &#9745; |
| Get the topics under the specified node | nodes/:node_name/topics        | &#9745; |
| Get specific topic details         | topics/:topic_id               | &#9745; |
| Get replies under the specified topic | topics/:topic_id/replies       | &#9745; |

## Installation

via [Swift Package Manager](https://swift.org/package-manager/) Install to your project，Add in `Package.swift`：

```swift
.package(name: "V2exAPI", url: "git@github.com:isaced/V2exAPI.git", .upToNextMinor(from: "1.0.0")),
```

## Useage

```swift
// Init V2eXAPI object
let v2ex = V2exAPI(accessToken: "XXXXX-XXXX-XXXX-XXXX-XXXXXXXXX")

// Get node list
let nodes = try await v2ex.nodesList()

// Get latest topics
let latest = try await v2ex.latestTopics()

// Get the topics under the specified node
let topics = try await v2ex.topics(nodeName: "swift", page: 1)

// Get replies under the specified topic
let replies = try await v2ex.replies(topicId: 870607, page: 1)
```

## API Reference

- [V2EX API interface](https://www.v2ex.com/p/7v9TEc53)
- [API 2.0 Beta](https://v2ex.com/help/api)

API Rate Limit

By default, each IP is limited to 120 API requests per hour. You can find the Rate Limit information in the HTTP header of the API return result:

```
X-Rate-Limit-Limit: 120
X-Rate-Limit-Reset: 1409479200
X-Rate-Limit-Remaining: 116
```

For API requests that can be cached by the CDN, the Rate Limit quota will only be consumed on the first request.

> Personal Access Token：https://v2ex.com/help/personal-access-token

## Examples

- [V2exOS](https://github.com/isaced/V2exOS) - A SwiftUI V2ex client for macOS

![screenshot](https://user-images.githubusercontent.com/2088605/182183782-79aa8524-dea4-40d3-87a3-6b542678f568.png#gh-dark-mode-only)
![screenshot](https://user-images.githubusercontent.com/2088605/182184352-52019bd0-da89-4703-9d83-2b85aa10617e.png##gh-light-mode-only)


## License

V2exAPI Kingfisher is released under the MIT license. See [LICENSE](/LICENSE) for details.
