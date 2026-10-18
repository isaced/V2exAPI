import Foundation
import XCTest

@testable import V2exAPI

/// V2 接口字段映射测试：用真实响应样本锁定结构与分页信息
final class V2ResponseMappingTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try decoder.decode(type, from: Data(json.utf8))
    }

    // MARK: - 通用包装

    func testEnvelopeFields() throws {
        let response = try decode(V2Response<V2Topic?>.self, LiveFixtures.v2Topic)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Topic details found")
        XCTAssertEqual(response.result??.id, 1000)
        // 非分页接口不应有 pagination
        XCTAssertNil(response.pagination)
    }

    func testMemberEndpointHasNoMessage() throws {
        // GET /member 的真实响应里没有 message 字段
        let response = try decode(V2Response<V2Member>.self, LiveFixtures.v2Member)
        XCTAssertTrue(response.success)
        XCTAssertNil(response.message)
        XCTAssertEqual(response.result?.username, "user-redacted")
    }

    // MARK: - 分页

    func testPaginationIsParsed() throws {
        let response = try decode(V2Response<[V2Topic]?>.self, LiveFixtures.v2NodeTopics)

        let pagination = try XCTUnwrap(response.pagination, "分页接口必须解析出 pagination")
        XCTAssertEqual(pagination.perPage, 20)
        XCTAssertEqual(pagination.total, 372)
        XCTAssertEqual(pagination.pages, 19)
    }

    func testRepliesPaginationIsParsed() throws {
        let response = try decode(V2Response<[V2Comment]?>.self, LiveFixtures.v2Replies)

        let pagination = try XCTUnwrap(response.pagination)
        XCTAssertNotNil(pagination.perPage)
        XCTAssertNotNil(pagination.total)
        XCTAssertNotNil(pagination.pages)
    }

    func testResponseWithoutPaginationDecodes() throws {
        let response = try decode(V2Response<V2Node?>.self, LiveFixtures.v2Node)
        XCTAssertNil(response.pagination)
    }

    // MARK: - V2Topic 独有字段

    func testV2TopicMapsV2OnlyFields() throws {
        let response = try decode(V2Response<V2Topic?>.self, LiveFixtures.v2Topic)
        let topic = try XCTUnwrap(response.result ?? nil)

        XCTAssertEqual(topic.id, 1000)
        XCTAssertNotNil(topic.title)
        XCTAssertNotNil(topic.content)
        XCTAssertNotNil(topic.contentRendered)
        XCTAssertEqual(topic.replies, 14)
        // V2 独有
        XCTAssertEqual(topic.syntax, 0)
        XCTAssertEqual(topic.stars, 0)
        XCTAssertEqual(topic.thanks, 0)
        XCTAssertEqual(topic.supplements?.count, 0)
        // V2 不返回 deleted，应为 nil
        XCTAssertNil(topic.deleted)
    }

    func testV2TopicNestedNodeUsesAvatarField() throws {
        let response = try decode(V2Response<V2Topic?>.self, LiveFixtures.v2Topic)
        let node = try XCTUnwrap(response.result??.node)

        XCTAssertNotNil(node.name)
        XCTAssertNotNil(node.avatar, "V2 使用单一 avatar 字段")
        // V1 才有的三尺寸头像在 V2 中缺失
        XCTAssertNil(node.avatarMini)
        XCTAssertNil(node.avatarLarge)
        XCTAssertNotNil(node.created)
        XCTAssertNotNil(node.lastModified)
    }

    // MARK: - V2Node

    func testV2NodeMapsV2OnlyFields() throws {
        let response = try decode(V2Response<V2Node?>.self, LiveFixtures.v2Node)
        let node = try XCTUnwrap(response.result ?? nil)

        XCTAssertEqual(node.name, "swift")
        XCTAssertNotNil(node.url)
        XCTAssertNotNil(node.title)
        XCTAssertNotNil(node.header)
        XCTAssertNotNil(node.footer)
        XCTAssertGreaterThan(node.topics ?? 0, 0)
        // V2 独有
        XCTAssertNotNil(node.avatar)
        XCTAssertNotNil(node.created)
        XCTAssertNotNil(node.lastModified)
        XCTAssertNotNil(node.founderId)
    }

    // MARK: - V2Token

    func testV2TokenMapsEveryField() throws {
        let response = try decode(V2Response<V2Token>.self, LiveFixtures.v2Token)
        let token = try XCTUnwrap(response.result)

        XCTAssertEqual(token.scope, "everything")
        XCTAssertEqual(token.expiration, 2592000)
        XCTAssertEqual(token.goodForDays, 30)
        XCTAssertNotNil(token.totalUsed)
        XCTAssertNotNil(token.lastUsed)
        XCTAssertNotNil(token.created)
    }

    // MARK: - V2Notification

    func testV2NotificationMapsEveryField() throws {
        let response = try decode(V2Response<[V2Notification]?>.self, LiveFixtures.v2Notifications)
        let list = try XCTUnwrap(response.result ?? nil)
        let notification = try XCTUnwrap(list.first)

        XCTAssertNotNil(notification.id)
        XCTAssertNotNil(notification.memberID)
        XCTAssertNotNil(notification.forMemberID)
        XCTAssertNotNil(notification.text)
        XCTAssertNotNil(notification.payloadRendered)
        XCTAssertNotNil(notification.created)
        XCTAssertNotNil(notification.member?.username)
        // 真实数据中 payload 为 null，可选项应能容纳
        XCTAssertNil(notification.payload)
    }

    // MARK: - V2Comment

    func testV2CommentMapsEveryField() throws {
        let response = try decode(V2Response<[V2Comment]?>.self, LiveFixtures.v2Replies)
        let list = try XCTUnwrap(response.result ?? nil)
        let comment = try XCTUnwrap(list.first)

        XCTAssertNotNil(comment.id)
        XCTAssertNotNil(comment.content)
        XCTAssertNotNil(comment.contentRendered)
        XCTAssertNotNil(comment.created)
        XCTAssertNotNil(comment.member?.username)
        // V2 的回复不含 topic_id / member_id / last_modified
        XCTAssertNil(comment.topicId)
        XCTAssertNil(comment.memberId)
        XCTAssertNil(comment.lastModified)
    }

    // MARK: - 无字段丢失

    func testNoV2FieldIsSilentlyDropped() throws {
        let expected: [String: Set<String>] = [
            LiveFixtures.v2Topic: ["success", "message", "result"],
            LiveFixtures.v2NodeTopics: ["success", "message", "pagination", "result"],
            LiveFixtures.v2Member: ["success", "result"],
        ]

        for (json, keys) in expected {
            let data = try XCTUnwrap(json.data(using: .utf8))
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let missing = keys.subtracting(object.keys)
            XCTAssertTrue(missing.isEmpty, "fixture 缺少预期字段: \(missing)")
        }
    }
}
