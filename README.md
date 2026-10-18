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

| 接口 | 方法 | 端点 | 需要 Token |
|------|------|------|:---:|
| 最热主题 | `hotTopics()` | [`/api/topics/hot.json`](https://v2ex.com/api/topics/hot.json) | 否 |
| 最新主题 | `latestTopics()` | [`/api/topics/latest.json`](https://v2ex.com/api/topics/latest.json) | 否 |
| 节点列表 | `nodesList(fields:sortBy:reverse:)` | [`/api/nodes/list.json`](https://v2ex.com/api/nodes/list.json) | 否 |
| 节点信息 | `nodesShow(name:)` | [`/api/nodes/show.json`](https://v2ex.com/api/nodes/show.json) | 否 |
| 用户主页 | `memberShow(username:id:)` | [`/api/members/show.json`](https://v2ex.com/api/members/show.json) | 否 |
| 回复列表 | `repliesAll(topicId:)` | [`/api/replies/show.json`](https://v2ex.com/api/replies/show.json) | 否 |
| 节点主题 | `nodeTopics(nodeName:)` | [`/api/topics/show.json`](https://v2ex.com/api/topics/show.json) | 否 |

> `nodes/list.json` 必须同时提供 `fields`、`sort_by`、`reverse` 三个参数，
> 缺少任何一个都会返回 `400`。其中 `reverse` 实测在服务端**不生效**。

### V2

| 接口 | 方法 | 端点 | 需要 Token |
|------|------|------|:---:|
| 获取最新的提醒 | `notifications(page:)` | [`/notifications`](https://www.v2ex.com/api/v2/notifications) | 是 |
| 删除指定的提醒 | `deleteNotification(notificationId:)` | [`/notifications/:id`](https://www.v2ex.com/api/v2/notifications) | 是 |
| 获取自己的 Profile | `member()` | [`/member`](https://www.v2ex.com/api/v2/member) | 是 |
| 查看当前使用的令牌 | `token()` | [`/token`](https://www.v2ex.com/api/v2/token) | 是 |
| 创建新的令牌 | `createToken(expiration:scope:)` | `/token` (POST) | 是 |
| 获取指定节点 | `getNode(nodeName:)` | `/nodes/:node_name` | 是 |
| 获取指定节点下的主题 | `topics(nodeName:page:)` | `/nodes/:node_name/topics` | 是 |
| 获取指定主题 | `topic(topicId:)` | `/topics/:topic_id` | 是 |
| 获取指定主题下的回复 | `replies(topicId:page:)` | `/topics/:topic_id/replies` | 是 |

> **实测结论**：V2 的**全部**接口都强制要求 Personal Access Token，
> 匿名请求一律返回 `401`（连 `nodes/:name` 这类纯读取接口也不例外）。
> 与之相对，**V1 的全部接口都无需 Token**。

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

每个 IP 的 API 请求数有配额限制（实测当前为 **600 次**，请以响应头为准）。
你可以在 API 返回结果的 HTTP 头部找到 Rate Limit 信息：

```
X-Rate-Limit-Limit: 600
X-Rate-Limit-Reset: 1409479200
X-Rate-Limit-Remaining: 576
```

本库会自动把这些头解析到 `V2exAPIError.RateLimit`，并在 HTTP 响应头缺失时
回退解析 V1 错误响应体中的 `rate_limit` 对象（`used` / `quota` / `reset_at`）。

对于能够被 CDN 缓存的 API 请求，只有第一次请求时，才会消耗 Rate Limit 配额。

> Personal Access Token 申请参考：https://v2ex.com/help/personal-access-token

## 使用示例

- [V2exOS](https://github.com/isaced/V2exOS) - 一个用 SwiftUI 编写的 V2ex macOS 客户端

![screenshot](https://user-images.githubusercontent.com/2088605/192312063-def16466-052b-457a-9b4c-856b2afb3a42.png#gh-dark-mode-only)
![screenshot](https://user-images.githubusercontent.com/2088605/192312051-9ec1e43d-4aee-46fb-a61f-fd865e35fca4.png##gh-light-mode-only)

## License

V2exAPI 在 MIT 许可下发布的，有关详细信息，请参阅 [LICENSE](/LICENSE)
