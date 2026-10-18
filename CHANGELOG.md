# Changelog

本项目的重要变更都会记录在此文件中。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 破坏性变更

- **需要 Swift 5.9+（Xcode 15+）**：`swift-tools-version` 从 5.6 升至 5.9，
  以启用 `ExistentialAny`、`ForwardTrailingClosures`、`DisableOutwardActorInference`。
- **返回值不再有外层 Optional**：接口由 `async throws -> T?` 改为
  `async throws -> T`，失败一律通过 `throw V2exAPIError` 表达。
- `memberShow()` 不传 `username` 或 `id` 时改为抛出 `V2exAPIError.invalidURL`，
  不再返回 `nil`。
- `V2Response.result` 由 `T` 改为 `T?`（部分接口成功时不返回 `result`）。
- `V2Comment` 除 `id` 外全部改为可选；`V2Node.name` 改为可选。
- `deleteNotification` 返回类型由 `V2Response<Data?>` 改为 `V2Response<V2EmptyResult>`。
- `topics(nodeName:)`（V1）改名为 `nodeTopics(nodeName:)`，旧方法保留但标记为 deprecated。

### 新增

- `V2exAPIError` 错误类型，包含 HTTP 状态码、服务端错误信息与限流信息，
  并提供 `isRateLimited` / `isUnauthorized` 等便捷属性。
- 解析 `X-Rate-Limit-*` 响应头为 `V2exAPIError.RateLimit`。
- 内置指数退避重试：默认重试 429 / 500 / 502 / 503 / 504 与临时网络错误，
  可通过 `maxRetries`、`retryDelay`、`retryableStatusCodes` 调整。
- **Linux 支持**（通过 `FoundationNetworking`）。
- `V2exAPI` 与全部模型遵循 `Sendable`；`V2Response` 支持条件
  `Equatable` / `Hashable` / `Sendable`。

### 修复

- 请求不再忽略 HTTP 状态码：401 / 403 / 429 等不再被误报为解码错误。
- V1 的 `nodes/show.json` 与 `members/show.json` 同时兼容数组与单对象两种响应形态。
- 路径参数做百分号编码，节点名包含特殊字符时不再构造出非法 URL。

### 文档与工程

- 全部 120 个 public 声明补齐 DocC 注释。
- 21 → 22 个离线单元测试（基于 `URLProtocol`，不再消耗真实 API 配额）。
- CI：lint、macOS 与 Linux(5.9/6.0) 测试、严格并发检查、四平台交叉编译、
  最低部署版本检查。
- 新增 `.swift-format` 配置，仅强制语义/安全类规则。

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
