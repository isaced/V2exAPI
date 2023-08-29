//
//  File.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 会员
public struct V2Member : Decodable, Hashable {
    
    public var id: Int?
    public var username: String?
    public var url: String?
    public var website: String?
    public var twitter: String?
    public var psn: String?
    public var github: String?
    public var btc: String?
    public var location: String?
    public var tagline: String?
    public var bio: String?
    public var avatar: String?
    public var avatarMini: String?
    public var avatarNormal: String?
    public var avatarLarge: String?
    public var created: Int?
    public var lastModified: Int?
    
    public init(id: Int? = nil, username: String? = nil, url: String? = nil, website: String? = nil, twitter: String? = nil, psn: String? = nil, github: String? = nil, btc: String? = nil, location: String? = nil, tagline: String? = nil, bio: String? = nil, avatar: String? = nil, avatarMini: String? = nil, avatarNormal: String? = nil, avatarLarge: String? = nil, created: Int? = nil, lastModified: Int? = nil) {
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
