//
//  File.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 话题
public struct V2Topic: Identifiable, Decodable {
    
    public let id: Int
    public let node: V2Node?
    public let member: V2Member?
    public let lastReplyBy: String?
    public let lastTouched: Int?
    public let title: String?
    public let url: String?
    public let created: Int?
    public let deleted: Int?
    public let content: String?
    public let contentRendered: String?
    public let lastModified: Int?
    public let replies: Int?
    
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
