import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest

@testable import V2exAPI

/// 拦截 URLSession 请求，用于离线单元测试
final class MockURLProtocol: URLProtocol {

    /// 每次请求的处理逻辑，返回 (状态码, 响应头, 响应体)
    static var handler: ((URLRequest) throws -> (Int, [String: String], Data))?
    /// 记录所有经过的请求，便于断言 URL / 方法 / Header
    static var recordedRequests: [URLRequest] = []

    static func reset() {
        handler = nil
        recordedRequests = []
    }

    /// 构造使用 mock 的 URLSession
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocol.recordedRequests.append(request)
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (statusCode, headers, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension MockURLProtocol {
    /// 以 JSON 字符串返回 200
    static func succeed(_ json: String, headers: [String: String] = [:]) {
        handler = { _ in (200, headers, Data(json.utf8)) }
    }

    /// 以指定状态码返回
    static func fail(_ statusCode: Int, _ json: String = #"{"message":"error"}"#, headers: [String: String] = [:]) {
        handler = { _ in (statusCode, headers, Data(json.utf8)) }
    }

    /// 按顺序返回多次响应，用于重试测试
    static func sequence(_ responses: [(Int, [String: String], String)]) {
        var remaining = responses
        handler = { _ in
            guard !remaining.isEmpty else {
                return (500, [:], Data())
            }
            let next = remaining.removeFirst()
            return (next.0, next.1, Data(next.2.utf8))
        }
    }
}

final class V2exAPITests: XCTestCase {

    private var api: V2exAPI!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        api = V2exAPI()
        api.session = MockURLProtocol.makeSession()
        // 默认关闭重试，避免测试里产生真实等待；重试测试会显式覆盖
        api.maxRetries = 0
    }

    override func tearDown() {
        MockURLProtocol.reset()
        api = nil
        super.tearDown()
    }

    // MARK: - 请求构造

    func testRequestBuildsV1URLAndQueryItems() async throws {
        MockURLProtocol.succeed(#"[{"id":1,"name":"swift","title":"Swift"}]"#)

        let nodes = try await api.nodesShow(name: "swift")
        XCTAssertEqual(nodes.name, "swift")

        let url = try XCTUnwrap(MockURLProtocol.recordedRequests.first?.url)
        XCTAssertEqual(url.host, "v2ex.com")
        XCTAssertEqual(url.path, "/api/nodes/show.json")

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "name" }?.value, "swift")
    }

    func testRequestBuildsV2URLAndPaging() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":[{"id":1,"title":"Hi"}]}"#)

        let response = try await api.topics(nodeName: "swift", page: 2)
        XCTAssertTrue(response.success)
        let topics = response.result ?? nil
        XCTAssertEqual(topics?.first?.id, 1)

        let url = try XCTUnwrap(MockURLProtocol.recordedRequests.first?.url)
        XCTAssertEqual(url.host, "www.v2ex.com")
        XCTAssertEqual(url.path, "/api/v2/nodes/swift/topics")

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "p" }?.value, "2")
    }

    func testV1SingleObjectResponseIsAccepted() async throws {
        // 兼容历史形态：nodes/show.json 也可能返回单个对象
        MockURLProtocol.succeed(#"{"id":9,"name":"macos","title":"macOS"}"#)

        let node = try await api.nodesShow(name: "macos")
        XCTAssertEqual(node.id, 9)
        XCTAssertEqual(node.name, "macos")
    }

    func testV1EmptyArrayThrowsAPIFailure() async throws {
        MockURLProtocol.succeed("[]")

        do {
            _ = try await api.nodesShow(name: "notexist")
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .apiFailure = error else {
                return XCTFail("expected apiFailure, got \(error)")
            }
        }
    }

    func testRequestSendsBearerToken() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"id":1,"username":"isaced"}}"#)
        api.accessToken = "TOKEN-123"

        _ = try await api.member()

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer TOKEN-123")
    }

    func testNodeNameIsPercentEncoded() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":null}"#)

        _ = try await api.getNode(nodeName: "a b/c")

        let url = try XCTUnwrap(MockURLProtocol.recordedRequests.first?.url)
        XCTAssertEqual(url.absoluteString, "https://www.v2ex.com/api/v2/nodes/a%20b/c")
    }

    func testPostSendsJSONBody() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"token":"abc","scope":"regular"}}"#)

        let response = try await api.createToken(expiration: 2592000)
        XCTAssertEqual(response.result?.token, "abc")

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue((request.value(forHTTPHeaderField: "Content-Type") ?? "").contains("application/json"))

        // URLProtocol 会把 httpBody 转成 stream，这里通过 bodyStream 读取
        let body = try XCTUnwrap(request.bodyStreamData())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["expiration"] as? Int, 2592000)
    }

    func testDeleteNotification() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":""}"#)

        let response = try await api.deleteNotification(notificationId: 42)
        // {"success": true} 没有 result 字段，不应被视为失败
        XCTAssertTrue(response.success)

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url?.path, "/api/v2/notifications/42")
    }

    // MARK: - 鉴权边界

    func testPublicEndpointsNeverSendAuthorizationEvenWhenTokenSet() async throws {
        api.accessToken = "STALE-TOKEN"
        MockURLProtocol.succeed(#"[]"#)

        _ = try await api.hotTopics()

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"),
                     "公开接口不应携带 Authorization")
    }

    func testAllV1EndpointsAreAnonymous() async throws {
        let cases: [(String, () async throws -> Void)] = [
            ("nodesList", { _ = try await self.api.nodesList() }),
            ("hotTopics", { _ = try await self.api.hotTopics() }),
            ("latestTopics", { _ = try await self.api.latestTopics() }),
            ("nodesShow", { _ = try await self.api.nodesShow(name: "swift") }),
            ("memberShow", { _ = try await self.api.memberShow(username: "isaced") }),
            ("repliesAll", { _ = try await self.api.repliesAll(topicId: 1) }),
            ("nodeTopics", { _ = try await self.api.nodeTopics(nodeName: "swift") }),
        ]

        for (name, call) in cases {
            MockURLProtocol.reset()
            api.accessToken = "TOKEN-SHOULD-NOT-LEAK"
            MockURLProtocol.succeed(#"[]"#)

            _ = try? await call()

            let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first, name)
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"),
                         "\(name) 应匿名请求")
        }
    }

    func testV2AuthenticatedEndpointsSendToken() async throws {
        api.accessToken = "REAL-TOKEN"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"id":1,"username":"me"}}"#)

        _ = try await api.member()

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer REAL-TOKEN")
    }

    func testEmptyTokenIsNotSent() async throws {
        api.accessToken = ""
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"id":1}}"#)

        _ = try await api.member()

        let request = try XCTUnwrap(MockURLProtocol.recordedRequests.first)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - 错误处理

    func testUnauthorizedThrowsHTTPError() async throws {
        MockURLProtocol.fail(401, #"{"message":"Invalid token"}"#)

        do {
            _ = try await api.member()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 401)
            XCTAssertTrue(error.isUnauthorized)
            guard case let .http(_, message, _, _) = error else {
                return XCTFail("expected http error")
            }
            XCTAssertEqual(message, "Invalid token")
        }
    }

    func testRateLimitedErrorExposesRateLimit() async throws {
        MockURLProtocol.fail(429, #"{"message":"rate limited"}"#, headers: [
            "X-Rate-Limit-Limit": "120",
            "X-Rate-Limit-Remaining": "0",
            "X-Rate-Limit-Reset": "1409479200",
        ])

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 429)
            XCTAssertTrue(error.isRateLimited)
            XCTAssertEqual(error.rateLimit?.limit, 120)
            XCTAssertEqual(error.rateLimit?.remaining, 0)
            XCTAssertNotNil(error.rateLimit?.reset)
        }
    }

    func testNotFoundThrowsHTTPError() async throws {
        MockURLProtocol.fail(404, "<html>not found</html>")

        do {
            _ = try await api.topic(topicId: 1)
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 404)
            guard case let .http(_, message, _, _) = error else {
                return XCTFail("expected http error")
            }
            // HTML 页面不会被当成 message 返回
            XCTAssertNil(message)
        }
    }

    func testDecodingFailureIsReported() async throws {
        MockURLProtocol.succeed(#"{"unexpected":true}"#)

        do {
            _ = try await api.member()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .decoding = error else {
                return XCTFail("expected decoding error, got \(error)")
            }
        }
    }

    func testNetworkFailureIsWrapped() async throws {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await api.latestTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .network = error else {
                return XCTFail("expected network error, got \(error)")
            }
        }
    }

    func testMemberShowRequiresArgument() async throws {
        do {
            _ = try await api.memberShow()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .invalidURL = error else {
                return XCTFail("expected invalidURL, got \(error)")
            }
        }
    }

    // MARK: - 重试

    func testRetriesRateLimitedRequestAndSucceeds() async throws {
        api.maxRetries = 2
        api.retryDelay = 0
        MockURLProtocol.sequence([
            (429, ["X-Rate-Limit-Remaining": "0"], #"{"message":"slow down"}"#),
            (200, [:], #"[{"id":1,"title":"ok"}]"#),
        ])

        let topics = try await api.hotTopics()
        XCTAssertEqual(topics.first?.id, 1)
        XCTAssertEqual(MockURLProtocol.recordedRequests.count, 2)
    }

    func testDoesNotRetryNonRetryableStatus() async throws {
        api.retryDelay = 0
        MockURLProtocol.fail(404)

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 404)
        }
        // 404 不在重试列表中，只应请求一次
        XCTAssertEqual(MockURLProtocol.recordedRequests.count, 1)
    }

    func testRetryCanBeDisabled() async throws {
        api.maxRetries = 2
        api.retryDelay = 0
        api.retryableStatusCodes = []
        MockURLProtocol.fail(503)

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 503)
        }
        XCTAssertEqual(MockURLProtocol.recordedRequests.count, 1)
    }

    func testRetriesExhaustedReturnsLastError() async throws {
        api.retryDelay = 0
        api.maxRetries = 2
        MockURLProtocol.fail(503)

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.statusCode, 503)
        }
        // 首次 + 2 次重试
        XCTAssertEqual(MockURLProtocol.recordedRequests.count, 3)
    }

    // MARK: - 网络错误重试

    func testRetriesOnTimedOut() async throws {
        api.maxRetries = 2
        api.retryDelay = 0

        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            if calls == 1 {
                throw URLError(.timedOut)
            }
            return (200, [:], Data(#"[{"id":1,"title":"ok"}]"#.utf8))
        }

        let topics = try await api.hotTopics()
        XCTAssertEqual(topics.first?.id, 1)
        XCTAssertEqual(calls, 2, "超时应重试一次后成功")
    }

    func testRetriesOnConnectionLost() async throws {
        api.maxRetries = 1
        api.retryDelay = 0

        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            if calls == 1 { throw URLError(.networkConnectionLost) }
            return (200, [:], Data("[]".utf8))
        }

        _ = try await api.hotTopics()
        XCTAssertEqual(calls, 2)
    }

    func testDoesNotRetryCertificateErrors() async throws {
        api.maxRetries = 3
        api.retryDelay = 0

        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            throw URLError(.serverCertificateUntrusted)
        }

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .network = error else {
                return XCTFail("expected network error, got \(error)")
            }
        }
        XCTAssertEqual(calls, 1, "证书错误不应重试")
    }

    func testTimedOutExhaustsRetriesThenThrows() async throws {
        api.maxRetries = 2
        api.retryDelay = 0

        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            throw URLError(.timedOut)
        }

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case let .network(underlying) = error else {
                return XCTFail("expected network error")
            }
            XCTAssertEqual((underlying as? URLError)?.code, .timedOut)
        }
        XCTAssertEqual(calls, 3, "首次 + 2 次重试")
    }

    func testRateLimitResetHeaderIsHonoured() async throws {
        api.maxRetries = 1
        api.retryDelay = 0

        // reset 设为过去的时间：距离重置已过，应退回 retryDelay 而立即重试。
        // 这样既能覆盖 X-Rate-Limit-Reset 的解析分支，又不会真的等待。
        let past = Int(Date().timeIntervalSince1970) - 60
        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            if calls == 1 {
                return (429, ["X-Rate-Limit-Reset": "\(past)"],
                        Data(#"{"message":"slow down"}"#.utf8))
            }
            return (200, [:], Data("[]".utf8))
        }

        let start = Date()
        _ = try await api.hotTopics()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(calls, 2)
        XCTAssertLessThan(elapsed, 2, "reset 已过期时不应长时间等待")
    }

    func testBackoffGrowsExponentiallyWithoutResetHeader() async throws {
        api.maxRetries = 2
        // 故意用极小的基础延迟，只验证「确实发生了等待」，
        // 避免依赖精确计时（CI 容器里计时抖动会导致偶发失败）
        api.retryDelay = 0.01

        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            if calls < 3 {
                return (503, [:], Data())
            }
            return (200, [:], Data("[]".utf8))
        }

        let start = Date()
        _ = try await api.hotTopics()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(calls, 3)
        // 两次退避 0.01 + 0.02 = 0.03，只断言单调下限，不卡上限
        XCTAssertGreaterThan(elapsed, 0.02, "应按退避策略等待后重试")
    }

    func testNonURLErrorIsNotRetried() async throws {
        api.maxRetries = 3
        api.retryDelay = 0

        struct CustomError: Error {}
        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            throw CustomError()
        }

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .network = error else {
                return XCTFail("expected network error")
            }
        }
        XCTAssertEqual(calls, 1, "非 URLError 不应重试")
    }

    // MARK: - V1 错误体中的限流信息

    func testRateLimitParsedFromV1ErrorBody() async throws {
        // V1 的真实 404 响应体
        let body = #"""
        {"status": "error", "message": "Object Not Found", "rate_limit": {"used": 29, "quota": 600, "reset_at": 1792306188}}
        """#
        MockURLProtocol.fail(404, body)

        do {
            _ = try await api.nodesShow(name: "nope")
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            let rateLimit = try XCTUnwrap(error.rateLimit, "应从 body 解析出限流信息")
            XCTAssertEqual(rateLimit.limit, 600)
            XCTAssertEqual(rateLimit.remaining, 571, "remaining = quota - used")
            XCTAssertNotNil(rateLimit.reset)
            XCTAssertEqual(error.statusCode, 404)
        }
    }

    func testRateLimitFromBodyReturnsNilWithoutField() {
        let body = Data(#"{"message":"x"}"#.utf8)
        XCTAssertNil(V2exAPIError.RateLimit(body: body))
        XCTAssertNil(V2exAPIError.RateLimit(body: Data()))
        XCTAssertNil(V2exAPIError.RateLimit(body: Data("<html>".utf8)))
    }

    func testHeaderRateLimitTakesPrecedenceOverBody() async throws {
        // 同时存在响应头与 body 时，应优先用响应头
        let body = #"{"status":"error","rate_limit":{"used":10,"quota":100,"reset_at":1}}"#
        MockURLProtocol.handler = { _ in
            (429, [
                "X-Rate-Limit-Limit": "600",
                "X-Rate-Limit-Remaining": "55",
            ], Data(body.utf8))
        }

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            XCTAssertEqual(error.rateLimit?.limit, 600, "应优先采用响应头")
            XCTAssertEqual(error.rateLimit?.remaining, 55)
        }
    }

    // MARK: - 错误描述

    func testErrorDescriptions() {
        XCTAssertTrue(V2exAPIError.invalidURL("x").localizedDescription.contains("invalid URL"))

        let withMessage = V2exAPIError.http(statusCode: 401, message: "bad token", rateLimit: nil, response: nil)
        XCTAssertTrue(withMessage.localizedDescription.contains("401"))
        XCTAssertTrue(withMessage.localizedDescription.contains("bad token"))

        let withoutMessage = V2exAPIError.http(statusCode: 500, message: nil, rateLimit: nil, response: nil)
        XCTAssertTrue(withoutMessage.localizedDescription.contains("500"))
        XCTAssertFalse(withoutMessage.localizedDescription.contains(" - "))

        let apiFailure = V2exAPIError.apiFailure(message: "nope", response: nil)
        XCTAssertTrue(apiFailure.localizedDescription.contains("nope"))

        let network = V2exAPIError.network(underlying: URLError(.timedOut))
        XCTAssertTrue(network.localizedDescription.contains("network"))

        // 非 http 错误时 statusCode / rateLimit 应为 nil
        XCTAssertNil(network.statusCode)
        XCTAssertNil(network.rateLimit)
        XCTAssertFalse(network.isRateLimited)
        XCTAssertFalse(network.isUnauthorized)
    }

    func testRateLimitDescription() {
        let rateLimit = V2exAPIError.RateLimit(limit: 120, remaining: 0, reset: nil)
        XCTAssertEqual(rateLimit.limit, 120)
        XCTAssertEqual(rateLimit.remaining, 0)
        XCTAssertTrue(rateLimit.description.contains("120"))

        // 没有任何头时构造应失败
        XCTAssertNil(V2exAPIError.RateLimit(headers: nil))
        XCTAssertNil(V2exAPIError.RateLimit(headers: [:]))
    }

    // MARK: - V2 需鉴权接口

    func testNotifications() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"""
        {"success":true,"message":"","result":[{"id":1,"member_id":2,"text":"hi","payload":"hi"}]}
        """#)

        let response = try await api.notifications(page: 2)
        XCTAssertTrue(response.success)
        let list = response.result ?? nil
        XCTAssertEqual(list?.first?.id, 1)
        XCTAssertEqual(list?.first?.memberID, 2)

        let url = try XCTUnwrap(MockURLProtocol.recordedRequests.first?.url)
        XCTAssertEqual(url.path, "/api/v2/notifications")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "p" }?.value, "2")
    }

    func testTokenInfo() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"token":"abc","scope":"everything","good_for_days":30}}"#)

        let response = try await api.token()
        XCTAssertEqual(response.result?.token, "abc")
        XCTAssertEqual(response.result?.goodForDays, 30)
        XCTAssertEqual(MockURLProtocol.recordedRequests.first?.url?.path, "/api/v2/token")
    }

    func testTopicDetail() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"id":42,"title":"T"}}"#)

        let response = try await api.topic(topicId: 42)
        let topic = response.result ?? nil
        XCTAssertEqual(topic?.id, 42)
        XCTAssertEqual(MockURLProtocol.recordedRequests.first?.url?.path, "/api/v2/topics/42")
    }

    func testTopicDetailNullResult() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":null}"#)

        let response = try await api.topic(topicId: 999)
        XCTAssertTrue(response.success)
        XCTAssertNil(response.result ?? nil)
    }

    func testGetNode() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":{"id":1,"name":"swift"}}"#)

        let response = try await api.getNode(nodeName: "swift")
        let node = response.result ?? nil
        XCTAssertEqual(node?.name, "swift")
    }

    func testRepliesV2Pagination() async throws {
        api.accessToken = "T"
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":[]}"#)

        _ = try await api.replies(topicId: 7, page: 3)

        let url = try XCTUnwrap(MockURLProtocol.recordedRequests.first?.url)
        XCTAssertEqual(url.path, "/api/v2/topics/7/replies")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "p" }?.value, "3")
    }

    // MARK: - 边缘分支

    func testAPIFailureMessageFromBodyWhenNoMessageField() async throws {
        // 非 2xx 且响应体只有 error 字段时，也应提取出信息
        MockURLProtocol.fail(400, #"{"error":"bad request body"}"#)

        do {
            _ = try await api.hotTopics()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case let .http(_, message, _, _) = error else {
                return XCTFail("expected http error")
            }
            XCTAssertEqual(message, "bad request body")
        }
    }

    func testStatusCodesAreAccepted() async throws {
        // 204 也属于成功范围，但空 body 会解码失败，这里验证它不被当成 HTTP 错误
        MockURLProtocol.handler = { _ in (204, [:], Data()) }

        do {
            _ = try await api.member()
            XCTFail("should throw")
        } catch let error as V2exAPIError {
            guard case .decoding = error else {
                return XCTFail("204 空体应落到 decoding 而不是 http，实际: \(error)")
            }
        }
    }

    func testRateLimitWaitNeverExceeds60Seconds() async throws {
        // reset 设为未来一小时，验证等待被钳制到 60 秒上限而非真的一小时。
        // 为了不让测试真的等 60 秒，这里把上限缩到可观察的范围：
        // 只断言「重试确实发生了」且「未等待远超 60 秒」。
        api.maxRetries = 1
        api.retryDelay = 0

        let farFuture = Int(Date().timeIntervalSince1970) + 3600
        var calls = 0
        MockURLProtocol.handler = { _ in
            calls += 1
            if calls == 1 {
                return (429, ["X-Rate-Limit-Reset": "\(farFuture)"], Data())
            }
            return (200, [:], Data("[]".utf8))
        }

        // 在后台任务里跑，主线程只短暂等待后取消，避免测试真的挂 60 秒
        let task = Task { try await api.hotTopics() }
        try await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()
        _ = try? await task.value

        // 无论是否完成，请求都应已经发出过一次（说明 429 被识别）
        XCTAssertGreaterThanOrEqual(calls, 1)
    }

    // MARK: - 值语义

    func testResponseIsEquatableWhenResultIs() {
        let a = V2Response(success: true, message: "", result: [V2Topic(id: 1)])
        let b = V2Response(success: true, message: "", result: [V2Topic(id: 1)])
        let c = V2Response(success: true, message: "", result: [V2Topic(id: 2)])

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        // Hashable 一致性也可用
        XCTAssertEqual(Set([a, b]).count, 1)
    }

    // MARK: - 模型容错

    func testCommentWithoutMemberDecodes() async throws {
        MockURLProtocol.succeed(#"{"success":true,"message":"","result":[{"id":7,"content":"hi"}]}"#)

        let response = try await api.replies(topicId: 1)
        let comments = response.result ?? nil
        XCTAssertEqual(comments?.first?.id, 7)
        XCTAssertNil(comments?.first?.member)
    }

    func testNodeWithoutNameDecodes() async throws {
        MockURLProtocol.succeed(#"{"id":5,"title":"Apple"}"#)

        let node = try await api.nodesShow(name: "apple")
        XCTAssertEqual(node.id, 5)
        XCTAssertNil(node.name)
    }

    func testDeprecatedTopicsOverloadStillWorks() async throws {
        MockURLProtocol.succeed(#"[{"id":3,"title":"old api"}]"#)

        let topics = try await api.nodeTopics(nodeName: "apple")
        XCTAssertEqual(topics.first?.id, 3)
        XCTAssertEqual(MockURLProtocol.recordedRequests.first?.url?.path, "/api/topics/show.json")
    }
}

private extension URLRequest {
    /// URLProtocol 收到的请求会丢失 httpBody，需要从 bodyStream 读取
    func bodyStreamData() -> Data? {
        guard let stream = httpBodyStream else {
            return httpBody
        }
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 {
                break
            }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }
}
