# V2exAPI 
[![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)](https://github.com/isaced/V2exAPI)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/isaced/V2exAPI)
[![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)](https://github.com/isaced/V2exAPI)

V2ex API 的 Swift 封装，支持 iOS/macOS。

## API 支持范围

### V1

| 接口   | 路径                   | 进度  |
|------|-------------------------|-----|
| 最热主题 | /api/topics/hot.json    | &#9745; |
| 最新主题 | /api/topics/latest.json | &#9745; |
| 节点信息 | /api/nodes/show.json    | &#9745; |
| 用户主页 | /api/members/show.json  | &#9745; |

### V2

| 接口            | 路径                           | 进度 |
|----------------------|--------------------------------|---------|
| 获取最新的提醒       | notifications                  | &#9744; |
| 删除指定的提醒       | notifications/:notification_id | &#9744; |
| 获取自己的 Profile   | member                         | &#9744; |
| 查看当前使用的令牌   | token                          | &#9744; |
| 获取指定节点         | nodes/:node_name               | &#9744; |
| 获取指定节点下的主题 | nodes/:node_name/topics        | &#9745; |
| 获取指定主题         | topics/:topic_id               | &#9744; |
| 获取指定主题下的回复 | topics/:topic_id/replies       | &#9744; |

## 安装

通过 [Swift Package Manager](https://swift.org/package-manager/) 安装 V2exAPI 到你的项目，在 `Package.swift` 中添加：

```swift
.package(name: "V2exAPI", url: "git@github.com:isaced/V2exAPI.git", .upToNextMinor(from: "0.0.1")),
```

## 使用

```swift
// 初始化 V2eXAPI 对象 
let v2ex = V2exAPI(accessToken: "XXXXX-XXXX-XXXX-XXXX-XXXXXXXXX")

// 获取节点列表
let nodes = try await v2ex.nodesList()

// 获取最新主题
let latest = try await v2ex.latestTopics()

// 获取指定节点下的主题列表
let topics = try await v2ex.topics(nodeName: "swift")
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
