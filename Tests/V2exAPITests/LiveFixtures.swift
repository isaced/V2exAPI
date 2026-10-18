import Foundation
import XCTest

@testable import V2exAPI

/// 取自 V2EX 真实返回的响应样本（单条、已脱敏）
///
/// 这些 fixture 锁定「服务端字段名 → 模型属性」的映射关系。
/// 若服务端增删字段或改动类型，解码测试会直接失败，
/// 而不是在运行时静默丢失数据。
enum LiveFixtures {

    /// topics/hot.json 的单条主题
    static let topic = #"""
{
  "node": {
    "avatar_large": "https://example.com/avatar.png",
    "name": "career",
    "avatar_normal": "https://example.com/avatar.png",
    "title": "职场话题",
    "url": "https://example.com",
    "topics": 24601,
    "footer": "",
    "header": "这里，我们聊聊那些工作中遇到的开心和不开心的事。",
    "title_alternative": "Career",
    "avatar_mini": "https://example.com/avatar.png",
    "stars": 3751,
    "founder_id": 0,
    "aliases": [],
    "root": false,
    "id": 770,
    "parent_node_name": ""
  },
  "member": {
    "id": 843658,
    "username": "user-redacted",
    "url": "https://example.com",
    "website": null,
    "twitter": null,
    "psn": null,
    "github": null,
    "btc": null,
    "location": null,
    "tagline": null,
    "bio": null,
    "avatar_mini": "https://example.com/avatar.png",
    "avatar_normal": "https://example.com/avatar.png",
    "avatar_large": "https://example.com/avatar.png",
    "created": 1787919438,
    "last_modified": 1787919438,
    "pro": 0
  },
  "last_reply_by": "user-redacted",
  "last_touched": 1792298047,
  "title": "0 基础入行金融需要多久？",
  "url": "https://example.com",
  "created": 1792242407,
  "deleted": 0,
  "content": "请教下金融大佬没有基础入行金融需要多久多久\r\n本人女研究生学历英语交流无障碍\r\n适合做金融哪个类目呢",
  "content_rendered": "<p>请教下金融大佬没有基础入行金融需要多久多久\n本人女研究生学历英语交流无障碍\n适合做金融哪个类目呢</p>\n",
  "last_modified": 1792284658,
  "replies": 79,
  "id": 1249646
}
"""#

    /// replies/show.json 的单条回复
    static let reply = #"""
{
  "member": {
    "id": 123,
    "username": "user-redacted",
    "url": "https://example.com",
    "website": "",
    "twitter": "romoo",
    "psn": "",
    "github": "romoo",
    "btc": "",
    "location": "Beijing, China",
    "tagline": "Aha",
    "bio": "",
    "avatar_mini": "https://example.com/avatar.png",
    "avatar_normal": "https://example.com/avatar.png",
    "avatar_large": "https://example.com/avatar.png",
    "created": 1272264436,
    "last_modified": 1692190135,
    "pro": 0
  },
  "created": 1280192713,
  "topic_id": 1000,
  "content": "右下角的图标该变成三个了。 ^^",
  "content_rendered": "右下角的图标该变成三个了。 ^^",
  "last_modified": 1335092396,
  "member_id": 123,
  "id": 6847
}
"""#

    /// nodes/show.json
    static let node = #"""
{
  "avatar_large": "https://example.com/avatar.png",
  "name": "swift",
  "avatar_normal": "https://example.com/avatar.png",
  "title": "Swift",
  "url": "https://example.com",
  "topics": 372,
  "footer": "",
  "header": "来自 Apple 的类型安全的编程语言。",
  "title_alternative": "Swift",
  "avatar_mini": "https://example.com/avatar.png",
  "stars": 552,
  "founder_id": 0,
  "aliases": [],
  "root": false,
  "id": 638,
  "parent_node_name": "programming"
}
"""#

    /// members/show.json
    static let member = #"""
{
  "id": 42376,
  "username": "user-redacted",
  "url": "https://example.com",
  "website": "www.isaced.com",
  "twitter": "isacedx",
  "psn": "",
  "github": "isaced",
  "btc": "",
  "location": "",
  "tagline": "",
  "bio": "",
  "avatar_mini": "https://example.com/avatar.png",
  "avatar_normal": "https://example.com/avatar.png",
  "avatar_large": "https://example.com/avatar.png",
  "created": 1374317846,
  "last_modified": 1664252897,
  "pro": 0,
  "status": "found"
}
"""#
}
