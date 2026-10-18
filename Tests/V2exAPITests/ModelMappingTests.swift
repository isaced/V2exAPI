import Foundation
import XCTest

@testable import V2exAPI

/// 字段映射测试：用真实响应样本验证模型能完整、正确地解码
final class ModelMappingTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try decoder.decode(type, from: Data(json.utf8))
    }

    // MARK: - V2Topic

    func testTopicMapsEveryField() throws {
        let topic = try decode(V2Topic.self, LiveFixtures.topic)

        XCTAssertEqual(topic.id, 1249646)
        XCTAssertEqual(topic.title, "0 基础入行金融需要多久？")
        XCTAssertEqual(topic.url, "https://example.com")
        XCTAssertEqual(topic.content, "请教下金融大佬没有基础入行金融需要多久多久\r\n本人女研究生学历英语交流无障碍\r\n适合做金融哪个类目呢")
        XCTAssertNotNil(topic.contentRendered)
        XCTAssertEqual(topic.created, 1792242407)
        XCTAssertEqual(topic.deleted, 0)
        XCTAssertEqual(topic.lastModified, 1792284658)
        XCTAssertEqual(topic.replies, 79)
        XCTAssertEqual(topic.lastReplyBy, "user-redacted")
        XCTAssertEqual(topic.lastTouched, 1792298047)
    }

    func testTopicNestedNodeMapsEveryField() throws {
        let topic = try decode(V2Topic.self, LiveFixtures.topic)
        let node = try XCTUnwrap(topic.node)

        XCTAssertEqual(node.id, 770)
        XCTAssertEqual(node.name, "career")
        XCTAssertEqual(node.title, "职场话题")
        XCTAssertEqual(node.topics, 24601)
        XCTAssertEqual(node.stars, 3751)
        XCTAssertEqual(node.footer, "")
        XCTAssertEqual(node.header, "这里，我们聊聊那些工作中遇到的开心和不开心的事。")
        XCTAssertEqual(node.titleAlternative, "Career")
        XCTAssertNotNil(node.url)
        XCTAssertNotNil(node.avatarLarge)
        XCTAssertNotNil(node.avatarNormal)
        XCTAssertNotNil(node.avatarMini)
        XCTAssertEqual(node.root, false)
        XCTAssertEqual(node.aliases, [])
        XCTAssertEqual(node.parentNodeName, "")
        // 曾经遗漏的字段
        XCTAssertEqual(node.founderId, 0)
    }

    func testTopicNestedMemberMapsEveryField() throws {
        let topic = try decode(V2Topic.self, LiveFixtures.topic)
        let member = try XCTUnwrap(topic.member)

        XCTAssertEqual(member.id, 843658)
        XCTAssertEqual(member.username, "user-redacted")
        XCTAssertEqual(member.created, 1787919438)
        XCTAssertEqual(member.lastModified, 1787919438)
        XCTAssertNotNil(member.avatarMini)
        XCTAssertNotNil(member.avatarNormal)
        XCTAssertNotNil(member.avatarLarge)
        // 曾遗漏的字段
        XCTAssertEqual(member.pro, 0)
    }

    // MARK: - V2Comment

    func testCommentMapsEveryField() throws {
        let comment = try decode(V2Comment.self, LiveFixtures.reply)

        XCTAssertGreaterThan(comment.id, 0)
        XCTAssertNotNil(comment.content)
        XCTAssertNotNil(comment.contentRendered)
        XCTAssertNotNil(comment.created)
        XCTAssertNotNil(comment.member?.username)
        // 曾遗漏的三个字段
        XCTAssertEqual(comment.topicId, 1000)
        XCTAssertNotNil(comment.memberId)
        XCTAssertNotNil(comment.lastModified)
    }

    // MARK: - V2Node

    func testNodeMapsEveryField() throws {
        let node = try decode(V2Node.self, LiveFixtures.node)

        XCTAssertEqual(node.name, "swift")
        XCTAssertEqual(node.id, 638)
        XCTAssertNotNil(node.title)
        XCTAssertNotNil(node.url)
        XCTAssertGreaterThan(node.topics ?? 0, 0)
        XCTAssertNotNil(node.footer)
        XCTAssertNotNil(node.header)
        XCTAssertNotNil(node.titleAlternative)
        XCTAssertNotNil(node.avatarMini)
        XCTAssertNotNil(node.avatarNormal)
        XCTAssertNotNil(node.avatarLarge)
        XCTAssertNotNil(node.stars)
        XCTAssertNotNil(node.aliases)
        XCTAssertNotNil(node.root)
        XCTAssertNotNil(node.parentNodeName)
        // 曾遗漏的字段
        XCTAssertNotNil(node.founderId)
    }

    // MARK: - V2Member

    func testMemberMapsEveryField() throws {
        let member = try decode(V2Member.self, LiveFixtures.member)

        XCTAssertEqual(member.id, 42376)
        XCTAssertEqual(member.username, "user-redacted")
        XCTAssertNotNil(member.url)
        XCTAssertNotNil(member.website)
        XCTAssertNotNil(member.twitter)
        XCTAssertNotNil(member.psn)
        XCTAssertNotNil(member.github)
        XCTAssertNotNil(member.btc)
        XCTAssertNotNil(member.location)
        XCTAssertNotNil(member.tagline)
        XCTAssertNotNil(member.bio)
        XCTAssertNotNil(member.avatarMini)
        XCTAssertNotNil(member.avatarNormal)
        XCTAssertNotNil(member.avatarLarge)
        XCTAssertNotNil(member.created)
        XCTAssertNotNil(member.lastModified)
        // 曾遗漏的字段
        XCTAssertEqual(member.pro, 0)
        XCTAssertEqual(member.status, "found")
    }

    // MARK: - 无字段丢失校验

    /// 把所有真实字段名与 CodingKeys 对比，确保没有字段被静默丢弃
    func testNoApiFieldIsSilentlyDropped() throws {
        let pairs: [(String, [String])] = [
            (LiveFixtures.topic, ["id", "node", "member", "last_reply_by", "last_touched",
                                  "title", "url", "created", "deleted", "content",
                                  "content_rendered", "last_modified", "replies",]),
            (LiveFixtures.reply, ["id", "member", "created", "topic_id", "content",
                                  "content_rendered", "last_modified", "member_id",]),
        ]

        for (json, expected) in pairs {
            let data = try XCTUnwrap(json.data(using: .utf8))
            let object = try XCTUnwrap(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let actual = Set(object.keys)
            let missing = Set(expected).subtracting(actual)
            XCTAssertTrue(missing.isEmpty, "fixture 缺少预期字段: \(missing)")
        }
    }
}
