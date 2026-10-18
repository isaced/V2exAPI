# Changelog

本项目的重要变更都会记录在此文件中。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 破坏性变更

- **需要 Swift 5.9+（Xcode 15+）工具链**：`swift-tools-version` 从 5.6 升至 5.9，
  以启用 `ExistentialAny`、`ForwardTrailingClosures`、`DisableOutwardActorInference`。
  协议作为类型时必须写 `any Decoder` / `any Error`。
- **返回值不再有外层 Optional**：接口由 `async throws -> T?` 改为
  `async throws -> T`，失败一律通过 `throw V2exAPIError` 表达。
- `memberShow()` 不传 `username` 或 `id` 时改为抛出 `V2exAPIError.invalidURL`，
  不再返回 `nil`。
- `V2Response.result` 由 `T` 改为 `T?`（部分接口成功时不返回 `result`）。
- `V2Comment` 除 `id` 外全部改为可选；`V2Node.name` 改为可选。
- `deleteNotification` 返回类型由 `V2Response<Data?>` 改为 `V2Response<V2EmptyResult>`。
- `topics(nodeName:)`（V1）改名为 `nodeTopics(nodeName:)`，旧方法保留但标记为 deprecated。

### 新增

- **`V2Response.pagination`**：分页接口的 `{per_page, total, pages}` 此前被完全丢弃，
  导致调用方无法实现正确的翻页 UI。
- **Linux 支持**（通过 `FoundationNetworking`，用 completion handler 桥接 async）。
- **内置指数退避重试**：默认重试 429 / 500 / 502 / 503 / 504 与临时网络错误，
  可通过 `maxRetries`、`retryDelay`、`retryableStatusCodes` 调整；
  若响应头带 `X-Rate-Limit-Reset` 会等待到配额重置（上限 60 秒）。
- **`V2exAPIError`**：包含 HTTP 状态码、服务端错误信息与限流信息，
  并提供 `statusCode` / `isRateLimited` / `isUnauthorized` / `rateLimit` 便捷属性。
- **公开接口自动匿名**：V1 的七个接口始终不带 `Authorization`，
  避免本地残留的过期令牌污染匿名请求。
- `V2exAPI` 与全部模型遵循 `Sendable`；`V2Response` 支持条件
  `Equatable` / `Hashable` / `Sendable`。
- 补齐此前被静默丢弃的字段：
  - `V2Node.founderId`、`V2Node.avatar`、`V2Node.created`、`V2Node.lastModified`
  - `V2Member.pro`、`V2Member.status`（`pro` 属性此前存在但没有 `CodingKeys`，
    始终解码为 `nil`）
  - `V2Comment.topicId`、`V2Comment.memberId`、`V2Comment.lastModified`
  - `V2Topic.syntax`、`V2Topic.stars`、`V2Topic.thanks`、`V2Topic.supplements`
    （含新增的 `V2Topic.Supplement` 类型）
- `V2exAPIError.RateLimit(body:)`：解析 V1 错误响应体中的 `rate_limit` 对象
  （`used` / `quota` / `reset_at`），响应头缺失时作为回退。

### 修复

- 请求不再忽略 HTTP 状态码：401 / 403 / 404 / 429 等不再被误报为解码错误。
- V1 的 `nodes/show.json` 与 `members/show.json` 同时兼容数组与单对象两种响应形态。
- 路径参数做百分号编码，节点名包含特殊字符时不再构造出非法 URL。
- 空字符串的 `accessToken` 不再被发送为空 `Bearer` 头。
- `nodes/list.json` 必须同时提供 `fields`、`sort_by`、`reverse` 三个参数，
  否则服务端返回 400（原实现默认值恰好正确，但此前无验证）。

### 文档

- 全部 public 声明补齐 DocC 注释。
- 每个接口标注是否需要访问令牌：**V2 全部需要，V1 全部不需要**（已实测）。
- 修正错误的限流额度说明（原写 120 次/小时，实测为 600，以响应头为准）。
- 标注 `nodesList` 的 `reverse` 参数在当前服务端**不生效**。
- 移除指向未发布 CocoaPods 包的徽章，改用 Swift Package Index 徽章与文档链接。

### 工程

- 测试从 1 个真网用例扩展为 **81 个**，覆盖率约 83%：
  - 49 个离线用例（`URLProtocol` mock，不消耗 API 配额）
  - 13 个真实网络用例（仅 V1 公开接口，`SKIP_NETWORK_TESTS=1` 可跳过）
  - 19 个字段映射用例（由真实响应 fixture 驱动，锁定结构）
- CI 覆盖：lint、macOS 与 Linux(5.9/6.0) 测试、真实 API 冒烟、严格并发检查、
  iOS/tvOS/watchOS 交叉编译、macOS 12 最低部署版本。
- 新增 `.swift-format` 配置（仅语义/安全类规则）、`.spi.yml`、
  `CONTRIBUTING.md`、`SECURITY.md`、Issue/PR 模板、`.gitattributes`。

## [1.1.1] - 2023-08-29

### 新增

- 模型支持 `Hashable`。

## [1.1.0] - 2022-10-29

### 新增

- 回复列表接口 `/api/replies/show.json`（无需认证）。
- `nodesList` 支持自定义 `fields` 等参数。

## [1.0.3] - 2022-09-30

### 新增

- 开放 `URLSession` 实例，便于定制（如代理）。

## [1.0.2] - 2022-09-29

### 修复

- 回复列表接口补充回复者头像字段。

## [1.0.1] - 2022-08-18

### 修复

- 修正部分类型声明。

## [1.0.0] - 2022-08-06

### 新增

- 首个正式版本，V1 / V2 接口覆盖度 100%。

[Unreleased]: https://github.com/isaced/V2exAPI/compare/1.1.1...HEAD
[1.1.1]: https://github.com/isaced/V2exAPI/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/isaced/V2exAPI/compare/1.0.3...1.1.0
[1.0.3]: https://github.com/isaced/V2exAPI/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/isaced/V2exAPI/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/isaced/V2exAPI/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/isaced/V2exAPI/releases/tag/1.0.0
