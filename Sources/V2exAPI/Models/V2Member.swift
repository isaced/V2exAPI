//
//  V2Member.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 会员
///
/// V1 的 `members/show.json` 与 V2 的 `member` 接口共用该模型。
public struct V2Member: Decodable, Hashable, Sendable {

    /// 数字 ID
    public var id: Int?
    /// 用户名
    public var username: String?
    /// 个人主页地址
    public var url: String?
    /// 个人网站
    public var website: String?
    /// Twitter 账号
    public var twitter: String?
    /// PSN 账号
    public var psn: String?
    /// GitHub 账号
    public var github: String?
    /// 比特币地址
    public var btc: String?
    /// 所在地
    public var location: String?
    /// 一句话签名
    public var tagline: String?
    /// 个人简介
    public var bio: String?
    /// 头像（默认尺寸）
    public var avatar: String?
    /// 头像（小尺寸）
    public var avatarMini: String?
    /// 头像（普通尺寸）
    public var avatarNormal: String?
    /// 头像（大尺寸）
    public var avatarLarge: String?
    /// 注册时间（Unix 时间戳，秒）
    public var created: Int?
    /// 资料最后修改时间（Unix 时间戳，秒）
    public var lastModified: Int?

    /// 手动构造，主要便于测试与 Mock
    public init(
        id: Int? = nil,
        username: String? = nil,
        url: String? = nil,
        website: String? = nil,
        twitter: String? = nil,
        psn: String? = nil,
        github: String? = nil,
        btc: String? = nil,
        location: String? = nil,
        tagline: String? = nil,
        bio: String? = nil,
        avatar: String? = nil,
        avatarMini: String? = nil,
        avatarNormal: String? = nil,
        avatarLarge: String? = nil,
        created: Int? = nil,
        lastModified: Int? = nil
    ) {
        self.id = id
        self.username = username
        self.url = url
        self.website = website
        self.twitter = twitter
        self.psn = psn
        self.github = github
        self.btc = btc
        self.location = location
        self.tagline = tagline
        self.bio = bio
        self.avatar = avatar
        self.avatarMini = avatarMini
        self.avatarNormal = avatarNormal
        self.avatarLarge = avatarLarge
        self.created = created
        self.lastModified = lastModified
    }

    enum CodingKeys: String, CodingKey {
        case id, username, url, website, twitter, psn, github, btc, location, tagline, bio, created, avatar
        case avatarMini = "avatar_mini"
        case avatarNormal = "avatar_normal"
        case avatarLarge = "avatar_large"
        case lastModified = "last_modified"
    }
}
