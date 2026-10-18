//
//  V2Comment.swift
//  
//
//  Created by isaced on 2022/7/31.
//

import Foundation

/// 回复
///
/// V2 接口在主题被删除、回复者已注销等场景下可能缺少 `member` 等字段，
/// 因此除 `id` 外的字段均为可选值。
public struct V2Comment: Identifiable, Decodable, Hashable {
    
    public let id: Int
    public let content: String?
    public let contentRendered: String?
    public let created: Int?
    public let member: V2Member?
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case contentRendered = "content_rendered"
        case created, member
    }
    
    public init(
        id: Int,
        content: String? = nil,
        contentRendered: String? = nil,
        created: Int? = nil,
        member: V2Member? = nil
    ) {
        self.id = id
        self.content = content
        self.contentRendered = contentRendered
        self.created = created
        self.member = member
    }
}
