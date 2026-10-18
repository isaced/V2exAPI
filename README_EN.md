# V2exAPI
[![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)](https://github.com/isaced/V2exAPI)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fisaced%2FV2exAPI%2Fbadge%3Ftype%3Dswift-versions&style=for-the-badge)](https://swiftpackageindex.com/isaced/V2exAPI)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fisaced%2FV2exAPI%2Fbadge%3Ftype%3Dplatforms&style=for-the-badge)](https://swiftpackageindex.com/isaced/V2exAPI)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/isaced/V2exAPI)
[![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)](https://github.com/isaced/V2exAPI)

[中文](/README.md)｜English

A [V2ex](https://v2ex.com/) API wrapper for iOS/macOS, built with Swift.

> V2EX is a community of start-ups, designers, developers and creative people.

## Features

- [x] SPM(Swift Package Manager) Support
- [x] Swift async/await Support
- [x] V2ex API V1 100%
- [x] V2ex API V2 100%
- [x] Structured errors via `V2exAPIError` (HTTP status / rate limit / decoding)
- [x] Built-in exponential backoff retry for 429 / 5xx / flaky connections
- [x] Linux support via `FoundationNetworking`
- [x] Zero dependency

> Requires Swift 5.9+ (Xcode 15+). Verified on iOS / macOS / tvOS / watchOS / Linux.

## API Support

### V1

| 接口   | 路径                   | 进度  |
|------|-------------------------|-----|
| Hottest topic | /api/topics/hot.json    | &#9745; |
| Latest Topics | /api/topics/latest.json | &#9745; |
| Node list | /api/nodes/list.json    | &#9745; |
| Node Info | /api/nodes/show.json    | &#9745; |
| Profile info | /api/members/show.json  | &#9745; |
| Replies | /api/replies/show.json  | &#9745; |

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

### Swift Package Manager

via [Swift Package Manager](https://swift.org/package-manager/) Install to your project，Add in `Package.swift`：

```swift
.package(url: "https://github.com/isaced/V2exAPI.git", from: "1.1.0"),
```

In Xcode：
- File > Swift Packages > Add Package Dependency
- Add https://github.com/isaced/V2exAPI.git
- Select "Up to Next Major" with "1.1.0"

### CocoaPods

> ⚠️ This package is **not published to the public CocoaPods trunk** yet.
> The snippet below requires publishing it yourself; prefer Swift Package Manager.

```ruby
pod 'V2exAPI', '~> 1.1'
```

### Documentation

DocC documentation is hosted by [Swift Package Index](https://swiftpackageindex.com/isaced/V2exAPI/documentation/v2exapi).

## Usage

```swift
import V2exAPI

// Init V2eXAPI object
let v2ex = V2exAPI(accessToken: "XXXXX-XXXX-XXXX-XXXX-XXXXXXXXX")

// Get node list
let nodes = try await v2ex.nodesList()

// Get latest topics
let latest = try await v2ex.latestTopics()

// Get the topics under the specified node (V1, returns `[V2Topic]`)
let topicsV1 = try await v2ex.nodeTopics(nodeName: "swift")

// Get the topics under the specified node (V2, returns `V2Response<[V2Topic]?>`)
let topics = try await v2ex.topics(nodeName: "swift", page: 1)

// Get replies under the specified topic
let replies = try await v2ex.replies(topicId: 870607, page: 1)
```

### Error handling

Every call throws `V2exAPIError` on failure, so you can branch on the status code
or on semantic helpers:

```swift
do {
    let topics = try await v2ex.topics(nodeName: "swift", page: 1)
    guard topics.success else {
        // Business failure, see topics.message
        return
    }
    print(topics.result ?? [])
} catch let error as V2exAPIError {
    if error.isRateLimited {
        print("Rate limited, remaining: \(error.rateLimit?.remaining ?? 0)")
    } else if error.isUnauthorized {
        // Token expired or invalid, ask the user to sign in again
    } else {
        print(error.localizedDescription)
    }
}
```

### Retry

`429` (rate limited) and `5xx` responses are retried with exponential backoff
(two attempts by default). When `X-Rate-Limit-Reset` is present, it waits until
the quota resets (capped at 60s). Everything is configurable:

```swift
var v2ex = V2exAPI(accessToken: "...")

v2ex.maxRetries = 3                     // 0 disables retrying
v2ex.retryDelay = 1                     // first wait, doubled each retry
v2ex.retryableStatusCodes = [429, 503]  // narrow the retry set
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

V2exAPI is released under the MIT license. See [LICENSE](/LICENSE) for details.
