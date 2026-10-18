//
//  V2exAPIError.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// V2EX API 请求错误
///
/// 所有 `V2exAPI` 抛出的错误都会被包装成该类型，
/// 便于调用方按状态码或错误种类做分支处理。
public enum V2exAPIError: Error, LocalizedError {

    /// URL 构造失败（例如节点名包含非法字符）
    case invalidURL(String)

    /// 服务端返回了非 2xx 状态码
    /// - Parameters:
    ///   - statusCode: HTTP 状态码
    ///   - message: 从响应体或 `V2Response.message` 中提取的错误信息
    ///   - rateLimit: 从响应头解析出的限流信息（如果服务端返回了）
    case http(statusCode: Int, message: String?, rateLimit: RateLimit?, response: URLResponse?)

    /// 响应体无法解码为期望的模型
    case decoding(underlying: Error, body: Data?)

    /// V2 接口返回 `success: false`
    case apiFailure(message: String?, response: URLResponse?)

    /// 网络层错误（无网络、超时、TLS 失败等）
    case network(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
            return "V2exAPI: invalid URL: \(url)"
        case let .http(statusCode, message, _, _):
            if let message, !message.isEmpty {
                return "V2exAPI: HTTP \(statusCode) - \(message)"
            }
            return "V2exAPI: HTTP \(statusCode)"
        case let .decoding(underlying, _):
            return "V2exAPI: failed to decode response - \(underlying)"
        case let .apiFailure(message, _):
            return "V2exAPI: request failed - \(message ?? "unknown error")"
        case let .network(underlying):
            return "V2exAPI: network error - \(underlying)"
        }
    }

    /// HTTP 状态码，非 HTTP 类错误返回 nil
    public var statusCode: Int? {
        if case let .http(statusCode, _, _, _) = self {
            return statusCode
        }
        return nil
    }

    /// 限流信息，仅当服务端返回了 `X-Rate-Limit-*` 响应头时存在
    public var rateLimit: RateLimit? {
        if case let .http(_, _, rateLimit, _) = self {
            return rateLimit
        }
        return nil
    }

    /// 是否因为触发限流而失败
    public var isRateLimited: Bool {
        statusCode == 429 || rateLimit?.remaining == 0
    }

    /// 是否因为 Token 无效或过期而失败
    public var isUnauthorized: Bool {
        statusCode == 401 || statusCode == 403
    }

    /// V2EX 的限流信息，来自响应头 `X-Rate-Limit-*`
    public struct RateLimit: Equatable, Sendable, CustomStringConvertible {
        /// 每小时允许的请求数
        public let limit: Int?
        /// 当前窗口内剩余请求数
        public let remaining: Int?
        /// 配额重置时间
        public let reset: Date?

        public init(limit: Int?, remaining: Int?, reset: Date?) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
        }

        public init?(headers: [AnyHashable: Any]?) {
            let limit = V2exAPIError.intValue(headers, "X-Rate-Limit-Limit")
            let remaining = V2exAPIError.intValue(headers, "X-Rate-Limit-Remaining")
            let reset = V2exAPIError.intValue(headers, "X-Rate-Limit-Reset").map {
                Date(timeIntervalSince1970: TimeInterval($0))
            }

            if limit == nil && remaining == nil && reset == nil {
                return nil
            }
            self.init(limit: limit, remaining: remaining, reset: reset)
        }

        public var description: String {
            "RateLimit(limit: \(limit.map(String.init) ?? "-"), remaining: \(remaining.map(String.init) ?? "-"), reset: \(reset.map { ISO8601DateFormatter().string(from: $0) } ?? "-"))"
        }
    }
}

extension V2exAPIError {

    /// 大小写不敏感地从响应头中取整数值
    static func intValue(_ headers: [AnyHashable: Any]?, _ name: String) -> Int? {
        guard let value = headers?.first(where: {
            ($0.key as? String)?.caseInsensitiveCompare(name) == .orderedSame
        })?.value else {
            return nil
        }
        if let number = value as? Int {
            return number
        }
        return (value as? String).flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// 从响应头构造限流信息
    static func rateLimit(from response: URLResponse?) -> RateLimit? {
        RateLimit(headers: (response as? HTTPURLResponse)?.allHeaderFields)
    }

    /// 尝试从响应体中提取错误信息
    static func message(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = object["message"] as? String, !message.isEmpty {
                return message
            }
            if let error = object["error"] as? String, !error.isEmpty {
                return error
            }
        }

        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty, text.count <= 300 else {
            return nil
        }
        // 避免把 HTML 错误页当作错误信息返回
        return text.hasPrefix("<") ? nil : text
    }
}
