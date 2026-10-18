# 安全政策

## 支持范围

| 版本 | 是否接收安全更新 |
|------|------------------|
| 1.x（最新 minor） | ✅ |
| 更早版本 | ❌ |

## 报告漏洞

**请不要通过公开 Issue 报告安全漏洞。**

请使用 GitHub 的私密报告功能：
<https://github.com/isaced/V2exAPI/security/advisories/new>

报告中请尽量包含：

- 受影响的版本
- 复现步骤或概念验证代码
- 可能的影响范围

一般会在 3 个工作日内回复；确认问题后会在修复发布时一并致谢。

## 关于访问令牌的提醒

本库只是 API 的封装，**不负责存储访问令牌**。使用时有几点需要开发者自行注意：

- 不要把 Personal Access Token 硬编码进源码或提交到仓库。
- 在 Apple 平台建议存入 Keychain；在 Linux 上请自行使用合适的密钥管理方案。
- 令牌一旦泄露，请立即到 <https://v2ex.com/settings/tokens> 吊销。
- 通过本库创建令牌后（`createToken`），返回值中含明文令牌，请避免随意打印到日志。

## 已知的边界

- `V2exAPIError` 的 `response`、`rateLimit` 等关联值包含服务端返回的内容，
  如需上报日志请自行脱敏。
- 本库不校验 TLS 证书链的额外策略，依赖系统 `URLSession` 的默认行为。
