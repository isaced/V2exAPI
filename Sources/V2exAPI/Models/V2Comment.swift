//
//  V2Comment.swift
//  
//
//  Created by isaced on 2022/7/31.
//

import Foundation

public struct V2Comment: Identifiable, Decodable, Hashable {
    
    public let id: Int
    public let content: String
    public let contentRendered: String
    public let created: Int
    public let member: V2Member
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case contentRendered = "content_rendered"
        case created, member
    }
    
    public init(id: Int, content: String, contentRendered: String, created: Int, member: V2Member) {
        self.id = id
        self.content = content
        self.contentRendered = contentRendered
        self.created = created
        self.member = member
    }
}
