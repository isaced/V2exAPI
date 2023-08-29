//
//  V2Node.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 节点
public struct V2Node: Identifiable, Decodable, Hashable {
    
    public let name: String
    public let title: String?
    public var id: Int?
    public let avatarLarge: String?
    public let avatarNormal: String?
    public let url: String?
    public let topics: Int?
    public let footer: String?
    public let header: String?
    public let titleAlternative: String?
    public let avatarMini: String?
    public let stars: Int?
    public let aliases: [String]?
    public let root: Bool?
    public let parentNodeName: String?
    
    public init(
        name: String, avatarLarge: String?, avatarNormal: String?, title: String?, url: String?,
        topics: Int?, footer: String?, header: String?, titleAlternative: String?, avatarMini: String?,
        stars: Int?, aliases: [String]?, root: Bool?, id: Int?, parentNodeName: String?
    ) {
        self.name = name
        self.avatarLarge = avatarLarge
        self.avatarNormal = avatarNormal
        self.title = title
        self.url = url
        self.topics = topics
        self.footer = footer
        self.header = header
        self.titleAlternative = titleAlternative
        self.avatarMini = avatarMini
        self.stars = stars
        self.aliases = aliases
        self.root = root
        self.id = id
        self.parentNodeName = parentNodeName
    }
    
    enum CodingKeys: String, CodingKey {
        case name, stars, aliases, root, id, title, url, topics, footer, header
        case avatarLarge = "avatar_large"
        case avatarNormal = "avatar_normal"
        case titleAlternative = "title_alternative"
        case avatarMini = "avatar_mini"
        case parentNodeName = "parent_node_name"
    }
}
