//
//  V2Node.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 节点
///
/// `nodes/show.json` 在节点不存在时可能不返回 `name`，
/// 因此除 `id` 外均为可选值，避免解码整体失败。
public struct V2Node: Identifiable, Decodable, Hashable, Sendable {
    
    public let name: String?
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
        name: String? = nil,
        avatarLarge: String? = nil,
        avatarNormal: String? = nil,
        title: String? = nil,
        url: String? = nil,
        topics: Int? = nil,
        footer: String? = nil,
        header: String? = nil,
        titleAlternative: String? = nil,
        avatarMini: String? = nil,
        stars: Int? = nil,
        aliases: [String]? = nil,
        root: Bool? = nil,
        id: Int? = nil,
        parentNodeName: String? = nil
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
