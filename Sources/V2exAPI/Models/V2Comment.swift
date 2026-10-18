//
//  V2Comment.swift
//
//
//  Created by isaced on 2022/7/31.
//

import Foundation

/// 回复
///
/// V1 的 `replies/show.json` 与 V2 的 `topics/:topic_id/replies` 接口共用该模型。
///
/// V2 接口在主题被删除、回复者已注销等场景下可能缺少 `member` 等字段，
/// 因此除 `id` 外的字段均为可选值。
public struct V2Comment: Identifiable, Decodable, Hashable, Sendable {

    /// 回复 ID
    public let id: Int
    /// 未经渲染的原文（通常是 Markdown）
    public let content: String?
    /// 已渲染为 HTML 的内容
    public let contentRendered: String?
    /// 创建时间（Unix 时间戳，秒）
    public let created: Int?
    /// 回复者（可能因用户注销而缺失）
    public let member: V2Member?
    /// 所属主题 ID
    public let topicId: Int?
    /// 回复者 ID
    public let memberId: Int?
    /// 最后修改时间（Unix 时间戳，秒）
    public let lastModified: Int?

    enum CodingKeys: String, CodingKey {
        case id, content
        case contentRendered = "content_rendered"
        case created, member
        case topicId = "topic_id"
        case memberId = "member_id"
        case lastModified = "last_modified"
    }

    /// 手动构造，主要便于测试与 Mock
    public init(
        id: Int,
        content: String? = nil,
        contentRendered: String? = nil,
        created: Int? = nil,
        member: V2Member? = nil,
        topicId: Int? = nil,
        memberId: Int? = nil,
        lastModified: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.contentRendered = contentRendered
        self.created = created
        self.member = member
        self.topicId = topicId
        self.memberId = memberId
        self.lastModified = lastModified
    }
}
