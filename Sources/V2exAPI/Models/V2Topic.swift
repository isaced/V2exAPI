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
    /// 正文所使用的语法标记（V2 独有，1 表示支持 Markdown）
    public let syntax: Int?
    /// 星标数（V2 独有）
    public let stars: Int?
    /// 感谢数（V2 独有）
    public let thanks: Int?
    /// 附言列表（V2 独有）
    public let supplements: [Supplement]?

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
        replies: Int? = nil,
        syntax: Int? = nil,
        stars: Int? = nil,
        thanks: Int? = nil,
        supplements: [Supplement]? = nil
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
        self.syntax = syntax
        self.stars = stars
        self.thanks = thanks
        self.supplements = supplements
    }

    enum CodingKeys: String, CodingKey {
        case node, member
        case lastReplyBy = "last_reply_by"
        case lastTouched = "last_touched"
        case title, url, created, deleted, content
        case contentRendered = "content_rendered"
        case lastModified = "last_modified"
        case replies, id
        case syntax, stars, thanks, supplements
    }
}

extension V2Topic {
    /// 主题附言（V2 独有）
    public struct Supplement: Decodable, Hashable, Sendable {
        /// 附言 ID
        public let id: Int?
        /// 附言原文
        public let content: String?
        /// 附言渲染后的 HTML
        public let contentRendered: String?
        /// 创建时间（Unix 时间戳，秒）
        public let created: Int?

        public init(id: Int? = nil, content: String? = nil, contentRendered: String? = nil, created: Int? = nil) {
            self.id = id
            self.content = content
            self.contentRendered = contentRendered
            self.created = created
        }

        enum CodingKeys: String, CodingKey {
            case id, content, created
            case contentRendered = "content_rendered"
        }
    }
}
