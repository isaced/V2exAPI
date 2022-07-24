//
//  File.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 会员
public struct V2Member: Decodable {

  public var id: Int
  public let username: String?
  public let url: String?
  public let website: String?
  public let twitter: String?
  public let psn: String?
  public let github: String?
  public let btc: String?
  public let location: String?
  public let tagline: String?
  public let bio: String?
  public let avatarMini: String?
  public let avatarNormal: String?
  public let avatarLarge: String?
  public let created: Int?
  public let lastModified: Int?

  public init(
    id: Int, username: String?, url: String?, website: String?, twitter: String?, psn: String?,
    github: String?, btc: String?, location: String?, tagline: String?, bio: String?,
    avatarMini: String?, avatarNormal: String?, avatarLarge: String?, created: Int?,
    lastModified: Int?
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
    self.avatarMini = avatarMini
    self.avatarNormal = avatarNormal
    self.avatarLarge = avatarLarge
    self.created = created
    self.lastModified = lastModified
  }

  enum CodingKeys: String, CodingKey {
    case id, username, url, website, twitter, psn, github, btc, location, tagline, bio, created
    case avatarMini = "avatar_mini"
    case avatarNormal = "avatar_normal"
    case avatarLarge = "avatar_large"
    case lastModified = "last_modified"
  }
}
