//
//  V2Response.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// V2EX API 的统一响应包装
///
/// V2 版本的所有接口都会返回形如 `{"success": true, "message": "", "result": ...}`
/// 的结构，本类型对应该结构。
///
/// `result` 为可选：部分接口（如删除提醒）成功时不会返回 `result` 字段，
/// 或返回 `null`。调用方仍应通过 `success` 判断业务是否成功。
///
/// ```swift
/// let response = try await v2ex.topics(nodeName: "swift")
/// guard response.success else {
///     print(response.message ?? "failed")
///     return
/// }
/// let topics = response.result ?? []
/// ```
public struct V2Response<T: Decodable>: Decodable {
    /// 业务是否成功
    public let success: Bool
    /// 服务端返回的说明，失败时通常包含原因
    public let message: String?
    /// 实际数据，可能为 `nil`
    public let result: T?
    /// 分页信息，仅分页接口（如节点主题、主题回复）会返回
    public let pagination: Pagination?

    /// 手动构造响应，主要便于测试与 Mock
    public init(
        success: Bool,
        message: String? = nil,
        result: T? = nil,
        pagination: Pagination? = nil
    ) {
        self.success = success
        self.message = message
        self.result = result
        self.pagination = pagination
    }
}

extension V2Response {
    /// 分页信息
    ///
    /// 分页接口会在响应顶层额外返回该对象，例如：
    /// `{"per_page": 20, "total": 372, "pages": 19}`
    public struct Pagination: Decodable, Hashable, Sendable {
        /// 每页条目数
        public let perPage: Int?
        /// 总条目数
        public let total: Int?
        /// 总页数
        public let pages: Int?

        public init(perPage: Int? = nil, total: Int? = nil, pages: Int? = nil) {
            self.perPage = perPage
            self.total = total
            self.pages = pages
        }

        enum CodingKeys: String, CodingKey {
            case perPage = "per_page"
            case total, pages
        }
    }
}

// 当 T 本身是 Equatable / Hashable 时才提供对应能力，
// 让调用方可以直接比较、用它做 SwiftUI 的 diff。
extension V2Response: Equatable where T: Equatable {}
extension V2Response: Hashable where T: Hashable {}
extension V2Response: Sendable where T: Sendable {}

// 合成实现会包含 pagination，因此无需额外处理

/// 仅用于解析错误响应体中的 `message` / `error` 字段
struct V2exAPIFailure: Decodable {
    let message: String?
    let error: String?
}
