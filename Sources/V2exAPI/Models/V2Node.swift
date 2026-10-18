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

    /// 节点名（半角英文或数字），如 `swift`
    public let name: String?
    /// 节点显示名称
    public let title: String?
    /// 数字 ID
    public var id: Int?
    /// 节点头像（大尺寸）
    public let avatarLarge: String?
    /// 节点头像（普通尺寸）
    public let avatarNormal: String?
    /// 节点主页地址
    public let url: String?
    /// 节点下主题数
    public let topics: Int?
    /// 节点页脚说明
    public let footer: String?
    /// 节点页首说明
    public let header: String?
    /// 节点名的中文/别名标题
    public let titleAlternative: String?
    /// 节点头像（小尺寸）
    public let avatarMini: String?
    /// 节点关注数
    public let stars: Int?
    /// 节点别名列表
    public let aliases: [String]?
    /// 是否为根节点
    public let root: Bool?
    /// 父节点名（存在父子关系时）
    public let parentNodeName: String?
    /// 节点创建者 ID（0 表示官方创建）
    public let founderId: Int?

    /// 手动构造，主要便于测试与 Mock
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
        parentNodeName: String? = nil,
        founderId: Int? = nil
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
        self.founderId = founderId
    }

    enum CodingKeys: String, CodingKey {
        case name, stars, aliases, root, id, title, url, topics, footer, header
        case avatarLarge = "avatar_large"
        case avatarNormal = "avatar_normal"
        case titleAlternative = "title_alternative"
        case avatarMini = "avatar_mini"
        case parentNodeName = "parent_node_name"
        case founderId = "founder_id"
    }
}
