//
//  File.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// 会员
public struct V2Member : Decodable {
  
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
  
  enum CodingKeys: String, CodingKey {
    case id, username, url, website, twitter, psn, github, btc, location, tagline, bio, created
    case avatarMini = "avatar_mini"
    case avatarNormal = "avatar_normal"
    case avatarLarge = "avatar_large"
    case lastModified = "last_modified"
  }
}
