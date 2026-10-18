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

    // MARK: - V2 真实响应（单条、已脱敏）

    /// GET /api/v2/topics/:id
    static let v2Topic = #"""
{
  "success": true,
  "message": "Topic details found",
  "result": {
    "id": 1000,
    "title": "Google App Engine x MobileMe",
    "content": "从现在开始，新上传到 V2EX 的头像将存储在 MobileMe iDisk 中。这是 V2EX 到目前为之所用到的第三个云。\r\n\r\n得益于这个架构升级，现在头像上传之后，将立刻在全站的所有页面更新。",
    "content_rendered": "从现在开始，新上传到 V2EX 的头像将存储在 MobileMe iDisk 中。这是 V2EX 到目前为之所用到的第三个云。\r\n<br />\r\n<br />得益于这个架构升级，现在头像上传之后，将立刻在全站的所有页面更新。",
    "syntax": 0,
    "url": "https://example.com",
    "replies": 14,
    "stars": 0,
    "thanks": 0,
    "last_reply_by": "user-redacted",
    "created": 1280192329,
    "last_modified": 1335004238,
    "last_touched": 1280285385,
    "member": {
      "id": 1,
      "username": "user-redacted",
      "bio": "",
      "website": "sepia.sol.build",
      "github": "",
      "url": "https://example.com",
      "avatar": "https://example.com/avatar.png",
      "created": 1272203146,
      "pro": 1792299120
    },
    "node": {
      "id": 1,
      "founder_id": 0,
      "url": "https://example.com",
      "name": "babel",
      "title": "Project Babel",
      "header": "",
      "footer": "",
      "avatar": "https://example.com/avatar.png",
      "topics": 1123,
      "created": 1272206882,
      "last_modified": 1700044199
    },
    "supplements": []
  }
}
"""#

    /// GET /api/v2/nodes/:name
    static let v2Node = #"""
{
  "success": true,
  "message": "Node details found",
  "result": {
    "id": 638,
    "founder_id": 0,
    "url": "https://example.com",
    "name": "swift",
    "title": "Swift",
    "header": "来自 Apple 的类型安全的编程语言。",
    "footer": "",
    "avatar": "https://example.com/avatar.png",
    "topics": 372,
    "created": 1355384712,
    "last_modified": 1661630260
  }
}
"""#

    /// GET /api/v2/nodes/:name/topics（含 pagination）
    static let v2NodeTopics = #"""
{
  "success": true,
  "message": "Node topics found",
  "result": [
    {
      "id": 1243658,
      "title": "我开源了一个 Swift 下的 Markdown 解析器和渲染器，如果你的项目中需要解析 Markdown，可以试试",
      "content": "代码在： https://github.com/daqing/danbo-swift-markdown",
      "content_rendered": "<p>代码在： <a href=\"https://github.com/daqing/danbo-swift-markdown\" rel=\"nofollow\">https://github.com/daqing/danbo-swift-markdown</a></p>\n",
      "syntax": 1,
      "url": "https://example.com",
      "replies": 2,
      "stars": 1,
      "thanks": 0,
      "last_reply_by": "user-redacted",
      "created": 1789974967,
      "last_modified": 1789975036,
      "last_touched": 1790522019
    }
  ],
  "pagination": {
    "per_page": 20,
    "total": 372,
    "pages": 19
  }
}
"""#

    /// GET /api/v2/topics/:id/replies（含 pagination）
    static let v2Replies = #"""
{
  "success": true,
  "message": "Topic replies found",
  "result": [
    {
      "id": 6847,
      "content": "右下角的图标该变成三个了。 ^^",
      "content_rendered": "右下角的图标该变成三个了。 ^^",
      "created": 1280192713,
      "member": {
        "id": 123,
        "username": "user-redacted",
        "bio": "",
        "website": "",
        "github": "romoo",
        "url": "https://example.com",
        "avatar": "https://example.com/avatar.png",
        "created": 1272264436,
        "pro": 0
      }
    }
  ],
  "pagination": {
    "per_page": 20,
    "total": 14,
    "pages": 1
  }
}
"""#

    /// GET /api/v2/member
    static let v2Member = #"""
{
  "success": true,
  "result": {
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
    "pro": 0
  }
}
"""#

    /// GET /api/v2/token
    static let v2Token = #"""
{
  "success": true,
  "message": "Current token details",
  "result": {
    "token": "REDACTED-TOKEN",
    "scope": "everything",
    "expiration": 2592000,
    "good_for_days": 30,
    "total_used": 13,
    "last_used": 1792303234,
    "created": 1792302304
  }
}
"""#

    /// GET /api/v2/notifications
    static let v2Notifications = #"""
{
  "success": true,
  "message": "Notifications 1-10/410",
  "result": [
    {
      "id": 28177232,
      "member_id": 348660,
      "for_member_id": 42376,
      "text": "<a href=\"/member/hannibalaikete\" target=\"_blank\"><strong>hannibalaikete</strong></a> 收藏了你发布的主题 › <a href=\"/t/883252#reply72\" class=\"topic-link\">V2exOS - 用 SwiftUI 写了一个 V2EX 客户端</a>",
      "payload": null,
      "payload_rendered": "",
      "created": 1786422119,
      "member": {
        "username": "user-redacted"
      }
    }
  ]
}
"""#

}
