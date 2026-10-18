//
//  V2Topic.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 主题
///
/// V1 与 V2 的多个接口共用该模型。
public struct V2Topic: Identifiable, Decodable, Hashable, Sendable {

    /// 主题 ID
    public let id: Int
    /// 所属节点
    public let node: V2Node?
    /// 发帖人
    public let member: V2Member?
    /// 最后回复者用户名
    public let lastReplyBy: String?
    /// 最后回复时间（Unix 时间戳，秒）
    public let lastTouched: Int?
    /// 标题
    public let title: String?
    /// 主题的网页地址
    public let url: String?
    /// 创建时间（Unix 时间戳，秒）
    public let created: Int?
    /// 删除标记（0 或 1）
    public let deleted: Int?
    /// 未经渲染的原文（通常是 Markdown）
    public let content: String?
    /// 已渲染为 HTML 的内容
    public let contentRendered: String?
    /// 最后修改时间（Unix 时间戳，秒）
    public let lastModified: Int?
    /// 回复数
    public let replies: Int?

    /// 手动构造，主要便于测试与 Mock
    public init(
        id: Int,
        node: V2Node? = nil,
        member: V2Member? = nil,
        lastReplyBy: String? = nil,
        lastTouched: Int? = nil,
        title: String? = nil,
        url: String? = nil,
        created: Int? = nil,
        deleted: Int? = nil,
        content: String? = nil,
        contentRendered: String? = nil,
        lastModified: Int? = nil,
        replies: Int? = nil
    ) {
        self.id = id
        self.node = node
        self.member = member
        self.lastReplyBy = lastReplyBy
        self.lastTouched = lastTouched
        self.title = title
        self.url = url
        self.created = created
        self.deleted = deleted
        self.content = content
        self.contentRendered = contentRendered
        self.lastModified = lastModified
        self.replies = replies
    }

    enum CodingKeys: String, CodingKey {
        case node, member
        case lastReplyBy = "last_reply_by"
        case lastTouched = "last_touched"
        case title, url, created, deleted, content
        case contentRendered = "content_rendered"
        case lastModified = "last_modified"
        case replies, id
    }
}
