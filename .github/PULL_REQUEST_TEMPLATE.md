## 改动内容

<!-- 说明这个 PR 做了什么 -->

## 为什么需要

<!-- 关联 Issue，或解释动机。review 时更关注「为什么」而不是「做了什么」 -->

Closes #

## 改动类型

- [ ] Bug 修复（不改变公开 API）
- [ ] 新功能（不改变公开 API）
- [ ] 破坏性变更（请在下节说明迁移方式）
- [ ] 文档 / 工程改进

## 破坏性变更说明

<!-- 若勾选了破坏性变更，请说明影响与迁移方式；否则可删除本节 -->

## 自检

- [ ] `swift build` 通过
- [ ] `swift test` 通过（新增行为已补测试）
- [ ] `swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors` 零警告
- [ ] `xcrun swift-format lint --configuration .swift-format --recursive Sources Tests` 无语义告警
- [ ] 新增/修改的 public API 已补 DocC 注释
- [ ] 已更新 `CHANGELOG.md` 的 `[Unreleased]` 段落
