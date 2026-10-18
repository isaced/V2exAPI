# 贡献指南

感谢你愿意为 V2exAPI 做出贡献！本文档说明本地开发、测试与提交的约定。

## 开发环境

- **Swift 5.9+**（Xcode 15 及以上）
- 无需任何第三方依赖

```bash
git clone https://github.com/isaced/V2exAPI.git
cd V2exAPI
swift build
swift test
```

## 提交前自检

请确保以下命令全部通过，CI 会做同样的事：

```bash
# 构建与测试
swift build
swift test

# 严格并发检查（必须零警告）
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors

# 代码规范（只检查语义/安全类规则）
xcrun swift-format lint --configuration .swift-format --recursive Sources Tests
```

格式化代码：

```bash
xcrun swift-format format --configuration .swift-format --in-place --recursive Sources Tests
```

> 注意：`.swift-format` 刻意只启用语义/安全类规则（如禁止强制解包），
> 不强制缩进、换行等排版规则，请保持现有 4 空格缩进风格。

## 代码约定

- 公共 API **必须**有 `///` DocC 注释。
- 不使用 `!` 强制解包、`try!`；预期中的失败用 `V2exAPIError` 表达。
- 新增/修改接口的行为时，请同步更新 `CHANGELOG.md` 的 `[Unreleased]` 段落。
- 新增接口需要附带对应的单元测试（使用 `MockURLProtocol`，**不要**在测试中访问真实网络）。

## 测试约定

测试基于 `URLProtocol` 拦截请求，全部离线运行，不会消耗 V2EX 的 API 配额：

```swift
func testSomething() async throws {
    MockURLProtocol.succeed(#"{"success":true,"result":[]}"#)
    let response = try await api.member()
    XCTAssertTrue(response.success)
}
```

## 分支与提交

- 从 `main` 拉出功能分支，命名如 `feat/retry-policy`、`fix/node-decoding`。
- 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)：
  `feat:`、`fix:`、`docs:`、`test:`、`chore:`、`refactor:`、`ci:`。
- 一个提交只做一件事，便于 review 与回滚。
- 涉及公开 API 变更时，请先开 Issue 讨论。

## Pull Request

- 描述清楚「为什么改」而不只是「改了什么」。
- 若属于破坏性变更，请在 PR 描述中标注并说明迁移方式。
- 请确认 CI 全绿后再请求 review。

## 行为准则

参与本项目即表示你同意保持友善、尊重不同观点，并对事不对人。
