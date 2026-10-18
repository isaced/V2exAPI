# V2exAPI
[![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)](https://github.com/isaced/V2exAPI)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fisaced%2FV2exAPI%2Fbadge%3Ftype%3Dswift-versions&style=for-the-badge)](https://swiftpackageindex.com/isaced/V2exAPI)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fisaced%2FV2exAPI%2Fbadge%3Ftype%3Dplatforms&style=for-the-badge)](https://swiftpackageindex.com/isaced/V2exAPI)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/isaced/V2exAPI)
[![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)](https://github.com/isaced/V2exAPI)

中文｜[English](/README_EN.md)

一个 [V2ex](https://v2ex.com/) API 的 Swift 封装，支持 iOS/macOS，支持 SPM 引入和 async/await 方式调用。

## 特性

- [x] SPM(Swift Package Manager) 支持
- [x] Swift async/await 异步 API
- [x] V2ex API V1 支持度 100%
- [x] V2ex API V2 支持度 100%
- [x] 结构化错误 `V2exAPIError`（HTTP 状态码 / 限流信息 / 解码失败）
- [x] 内置指数退避重试（429 / 5xx / 网络抖动，可配置）
- [x] 支持 Linux（`FoundationNetworking`）
- [x] Zero dependency 零三方依赖

> 需要 Swift 5.9+（Xcode 15+）工具链。已在 iOS / macOS / tvOS / watchOS / Linux 上验证。

## API 支持范围

### V1

| 接口   | 路径                   | 进度  |
|------|-------------------------|-----|
| 最热主题 | /api/topics/hot.json    | &#9745; |
| 最新主题 | /api/topics/latest.json | &#9745; |
| 节点列表 | /api/nodes/list.json    | &#9745; |
| 节点信息 | /api/nodes/show.json    | &#9745; |
| 用户主页 | /api/members/show.json  | &#9745; |
| 回复列表 | /api/replies/show.json  | &#9745; |

### V2

| 接口            | 路径                           | 进度 |
|----------------------|--------------------------------|---------|
| 获取最新的提醒       | notifications                  | &#9745; |
| 删除指定的提醒       | notifications/:notification_id | &#9745; |
| 获取自己的 Profile   | member                         | &#9745; |
| 查看当前使用的令牌   | token                          | &#9745; |
| 获取指定节点         | nodes/:node_name               | &#9745; |
| 获取指定节点下的主题 | nodes/:node_name/topics        | &#9745; |
| 获取指定主题         | topics/:topic_id               | &#9745; |
| 获取指定主题下的回复 | topics/:topic_id/replies       | &#9745; |

## 安装

### Swift Package Manager

通过 [Swift Package Manager](https://swift.org/package-manager/) 安装 V2exAPI 到你的项目，在 `Package.swift` 中添加：

```swift
.package(url: "https://github.com/isaced/V2exAPI.git", from: "1.1.0"),
```

在 Xcode 中：
- 菜单 File > Swift Packages > Add Package Dependency
- 搜索 https://github.com/isaced/V2exAPI.git
- 选择 "Up to Next Major" 版本 "1.1.0"


### CocoaPods

> ⚠️ 本包目前**尚未发布到 CocoaPods 公共源**，下面的用法需要先通过
> `pod spec lint` 自行发布，或改用上面的 SPM 方式（推荐）。

```ruby
pod 'V2exAPI', '~> 1.1'
```

### 文档

DocC 文档由 [Swift Package Index](https://swiftpackageindex.com/isaced/V2exAPI/documentation/v2exapi) 托管。

## 使用

```swift
import V2exAPI

// 初始化 V2eXAPI 对象 
let v2ex = V2exAPI(accessToken: "XXXXX-XXXX-XXXX-XXXX-XXXXXXXXX")

// 获取节点列表
let nodes = try await v2ex.nodesList()

// 获取最新主题
let latest = try await v2ex.latestTopics()

// 获取指定节点下的主题列表（V1，返回 `[V2Topic]`）
let topicsV1 = try await v2ex.nodeTopics(nodeName: "swift")

// 获取指定节点下的主题（V2，返回 `V2Response<[V2Topic]?>`）
let topics = try await v2ex.topics(nodeName: "swift", page: 1)

// 获取指定主题下的回复
let replies = try await v2ex.replies(topicId: 870607, page: 1)
```

### 错误处理

所有接口在失败时抛出 `V2exAPIError`，可以直接按状态码或语义判断：

```swift
do {
    let topics = try await v2ex.topics(nodeName: "swift", page: 1)
    guard topics.success else {
        // 业务失败，topics.message 中有服务端说明
        return
    }
    print(topics.result ?? [])
} catch let error as V2exAPIError {
    switch error {
    case .http(let statusCode, _, let rateLimit, _) where statusCode == 429:
        print("触发限流，剩余 \(rateLimit?.remaining ?? 0) 次")
    case let .network(underlying):
        print("网络错误：\(underlying)")
    case let .decoding(underlying, _):
        print("解析失败：\(underlying)")
    default:
        print(error.localizedDescription)
    }
}

// 也可以使用便捷属性
if let error = error as? V2exAPIError, error.isUnauthorized {
    // Token 失效，引导用户重新登录
}
```

### 重试

默认对 `429`（限流）和 `5xx` 做指数退避重试，最多 2 次；若响应头带
`X-Rate-Limit-Reset`，会等待到配额重置（上限 60 秒）。可自行调整：

```swift
var v2ex = V2exAPI(accessToken: "...")

v2ex.maxRetries = 3                 // 最大重试次数，0 表示关闭
v2ex.retryDelay = 1                 // 首次等待秒数，之后按 2 倍递增
v2ex.retryableStatusCodes = [429, 503]  // 只想重试这两类
```

## API 参考

- [V2EX API 接口](https://www.v2ex.com/p/7v9TEc53)
- [API 2.0 Beta](https://v2ex.com/help/api)

API Rate Limit

默认情况下，每个 IP 每小时可以发起的 API 请求数被限制在 120 次。你可以在 API 返回结果的 HTTP 头部找到 Rate Limit 信息：

```
X-Rate-Limit-Limit: 120
X-Rate-Limit-Reset: 1409479200
X-Rate-Limit-Remaining: 116
```

对于能够被 CDN 缓存的 API 请求，只有第一次请求时，才会消耗 Rate Limit 配额。

> Personal Access Token 申请参考：https://v2ex.com/help/personal-access-token

## 使用示例

- [V2exOS](https://github.com/isaced/V2exOS) - 一个用 SwiftUI 编写的 V2ex macOS 客户端

![screenshot](https://user-images.githubusercontent.com/2088605/192312063-def16466-052b-457a-9b4c-856b2afb3a42.png#gh-dark-mode-only)
![screenshot](https://user-images.githubusercontent.com/2088605/192312051-9ec1e43d-4aee-46fb-a61f-fd865e35fca4.png##gh-light-mode-only)

## License

V2exAPI 在 MIT 许可下发布的，有关详细信息，请参阅 [LICENSE](/LICENSE)
