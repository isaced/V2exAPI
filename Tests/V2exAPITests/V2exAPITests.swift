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
