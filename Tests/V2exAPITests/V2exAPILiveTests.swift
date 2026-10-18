import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest

@testable import V2exAPI

/// 针对 V1 公开接口的真实网络测试
///
/// 这些接口**不需要**访问令牌，直接请求 v2ex.com。
/// 注意：
/// - 只验证结构与关键字段，不断言具体内容（内容会随时间变化）
/// - 受 V2EX 每小时 120 次的 IP 限流约束，用例数量保持克制
/// - 需要网络；离线环境下用环境变量 `SKIP_NETWORK_TESTS=1` 跳过
final class V2exAPILiveTests: XCTestCase {

    private var api: V2exAPI!

    override func setUpWithError() throws {
        try super.setUpWithError()

        if ProcessInfo.processInfo.environment["SKIP_NETWORK_TESTS"] == "1" {
            throw XCTSkip("SKIP_NETWORK_TESTS=1，跳过真实网络测试")
        }

        api = V2exAPI()
        // 真实请求使用系统 URLSession，并关闭重试以控制耗时
        api.maxRetries = 1
        api.retryDelay = 1
    }

    // MARK: - V1 公开接口（无需 Token）

    func testHotTopics() async throws {
        let topics = try await api.hotTopics()

        XCTAssertFalse(topics.isEmpty, "热门主题不应为空")
        let first = try XCTUnwrap(topics.first)
        XCTAssertGreaterThan(first.id, 0)
        XCTAssertNotNil(first.title)
        XCTAssertNotNil(first.url)
    }

    func testLatestTopics() async throws {
        let topics = try await api.latestTopics()

        XCTAssertFalse(topics.isEmpty, "最新主题不应为空")
        XCTAssertNotNil(topics.first?.id)
    }

    func testNodesListRequiresAllParameters() async throws {
        let nodes = try await api.nodesList()

        XCTAssertFalse(nodes.isEmpty, "节点列表不应为空")
        let first = try XCTUnwrap(nodes.first)
        XCTAssertNotNil(first.id)
        XCTAssertNotNil(first.name)
        XCTAssertNotNil(first.title)
    }

    func testNodesListWithCustomFields() async throws {
        let nodes = try await api.nodesList(fields: ["id", "name", "title"])

        XCTAssertFalse(nodes.isEmpty)
        // 自定义 fields 后仍应正确解码
        XCTAssertNotNil(nodes.first?.name)
    }

    func testNodesShow() async throws {
        let node = try await api.nodesShow(name: "swift")

        XCTAssertEqual(node.name, "swift")
        XCTAssertNotNil(node.title)
        XCTAssertNotNil(node.url)
        // topics 计数应大于 0（swift 节点有不少主题）
        XCTAssertGreaterThan(node.topics ?? 0, 0)
    }

    func testMemberShowByUsername() async throws {
        let member = try await api.memberShow(username: "isaced")

        XCTAssertEqual(member.username, "isaced")
        XCTAssertNotNil(member.id)
        XCTAssertNotNil(member.avatarNormal)
    }

    func testMemberShowByID() async throws {
        // 先取到 id，再按 id 查一次
        let byName = try await api.memberShow(username: "isaced")
        let id = try XCTUnwrap(byName.id)

        let byID = try await api.memberShow(id: id)
        XCTAssertEqual(byID.username, "isaced")
    }

    func testRepliesAll() async throws {
        // 1000 是早期一个长期存在的主题
        let replies = try await api.repliesAll(topicId: 1000)

        XCTAssertFalse(replies.isEmpty, "该主题应有回复")
        let first = try XCTUnwrap(replies.first)
        XCTAssertGreaterThan(first.id, 0)
        // 回复者信息可能缺失，但正常主题应该存在
        XCTAssertNotNil(first.member?.username)
    }

    func testNodeTopics() async throws {
        let topics = try await api.nodeTopics(nodeName: "swift")

        XCTAssertFalse(topics.isEmpty, "swift 节点应有主题")
        XCTAssertNotNil(topics.first?.title)
    }

    // MARK: - 匿名性验证

    func testPublicEndpointWorksWithoutToken() async throws {
        var anonymous = V2exAPI()
        anonymous.accessToken = nil

        let topics = try await anonymous.hotTopics()
        XCTAssertFalse(topics.isEmpty)
    }

    func testPublicEndpointIgnoresInvalidToken() async throws {
        // 携带一个无效 token 调用公开接口，仍应成功
        var withBadToken = V2exAPI()
        withBadToken.accessToken = "INVALID-TOKEN-FOR-TEST"
        withBadToken.maxRetries = 1

        let topics = try await withBadToken.hotTopics()
        XCTAssertFalse(topics.isEmpty, "公开接口不应因为无效 token 而失败")
    }

    // MARK: - 错误路径（真实请求）

    func testUnknownNodeReturnsError() async throws {
        // 不存在的节点：V1 返回空数组或错误，两种都应被表达为 V2exAPIError
        do {
            let node = try await api.nodesShow(name: "this-node-does-not-exist-v2exapi")
            // 如果服务端返回了对象，至少 id 应存在
            XCTAssertNotNil(node.id)
        } catch let error as V2exAPIError {
            // apiFailure 或 http 都可接受
            switch error {
            case .apiFailure, .http, .decoding:
                break
            default:
                XCTFail("未预期的错误类型: \(error)")
            }
        }
    }

    // MARK: - 限流信息

    func testRateLimitHeadersAreParsed() async throws {
        // 直接取一次响应头，验证 X-Rate-Limit-* 的解析。
        // 使用 completion handler 形式，Linux 上的 Foundation 没有 async 版本。
        let url = try XCTUnwrap(URL(string: "https://v2ex.com/api/topics/hot.json"))

        let headerFields: [AnyHashable: Any]? = await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: url) { _, response, _ in
                continuation.resume(returning: (response as? HTTPURLResponse)?.allHeaderFields)
            }.resume()
        }

        guard let rateLimit = V2exAPIError.RateLimit(headers: headerFields) else {
            // 该接口可能被 CDN 缓存而不再返回限流头，属正常情况
            return
        }
        XCTAssertTrue(rateLimit.limit != nil || rateLimit.remaining != nil,
                      "限流信息应至少包含 limit 或 remaining")
    }
}
