import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// V2ex API 的客户端
///
/// 值类型，所有请求方法都是无状态的 `async` 调用，
/// 可安全地在多个 actor / Task 之间传递。
///
/// ```swift
/// let v2ex = V2exAPI(accessToken: "你的 Token")
///
/// let hot = try await v2ex.hotTopics()
/// let topics = try await v2ex.topics(nodeName: "swift", page: 1)
/// ```
///
/// 所有接口在失败时抛出 ``V2exAPIError``，其中包含 HTTP 状态码与限流信息。
/// 默认会对 429 / 5xx 与临时网络错误做指数退避重试，可通过
/// ``maxRetries``、``retryDelay``、``retryableStatusCodes`` 调整。
///
/// > Note: 标记为 `@unchecked Sendable` 是因为 Linux 的 Foundation 未将
/// > `URLSession` 声明为 `Sendable`；本类型只做无状态请求，实际是线程安全的。
public struct V2exAPI: @unchecked Sendable {
    
    /// 个人访问令牌
    ///
    /// 生成参考：<https://v2ex.com/help/personal-access-token>。
    /// 仅 V2 接口需要；为 `nil` 时请求不带 `Authorization` 头。
    public var accessToken: String?

    /// 发起请求使用的 `URLSession`
    ///
    /// 可替换为自定义实例以启用缓存、代理或用于测试注入。
    public var session = URLSession.shared

    /// 可重试的状态码，命中时按 `maxRetries` 指数退避重试
    ///
    /// 默认包含 429（限流）与 5xx，可通过设为空集合关闭重试。
    public var retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]

    /// 最大重试次数，0 表示不重试
    public var maxRetries: Int = 2

    /// 首次重试的等待时间，后续按 2 的倍数递增
    public var retryDelay: TimeInterval = 1

    /// 创建客户端
    /// - Parameter accessToken: 可选的个人访问令牌，仅 V2 接口需要。
    ///   也可以稍后通过 ``accessToken`` 属性设置。
    public init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }
    
    /**
     HTTP 请求

     成功时返回解码后的模型与原始响应；失败时抛出 `V2exAPIError`，
     包含 HTTP 状态码、限流信息或解码错误。

     - parameter  httpMethod: HTTP 方法，默认 GET
     - parameter  path: 相对 `endpoint` 的路径，不含前导 `/`
     - parameter  args: 请求参数，GET 拼到 query，POST 放进 JSON body
     - parameter  decodeClass: 期望解码的模型类型
     - parameter  endpoint: 使用的 API 版本，默认 V2
     */
    private func request<T>(
        httpMethod: String = "GET",
        path: String,
        args: [String: Any]? = nil,
        decodeClass: T.Type,
        endpoint: Endpoint = .v2
    ) async throws -> (T, URLResponse) where T : Decodable {
        let urlString = endpoint.baseURL + path
        guard let url = URL(string: urlString) else {
            throw V2exAPIError.invalidURL(urlString)
        }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw V2exAPIError.invalidURL(urlString)
        }

        if httpMethod != "POST", let args = args, !args.isEmpty {
            urlComponents.queryItems = args.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }

        guard let requestUrl = urlComponents.url else {
            throw V2exAPIError.invalidURL(urlString)
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken = accessToken {
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        if httpMethod == "POST", let args = args, !args.isEmpty {
            request.httpBody = try? JSONSerialization.data(withJSONObject: args)
        }

        let (data, response) = try await perform(request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            // 非 2xx：把状态码、服务端错误信息和限流信息一并抛出
            var message = V2exAPIError.message(from: data)
            if message == nil,
               let body = try? JSONDecoder().decode(V2exAPIFailure.self, from: data) {
                message = body.message
            }
            throw V2exAPIError.http(
                statusCode: httpResponse.statusCode,
                message: message,
                rateLimit: V2exAPIError.rateLimit(from: httpResponse),
                response: httpResponse
            )
        }

        do {
            let obj = try JSONDecoder().decode(decodeClass.self, from: data)
            return (obj, response)
        } catch {
            throw V2exAPIError.decoding(underlying: error, body: data)
        }
    }

    /**
     跨平台发起请求

     Apple 平台使用 `URLSession.data(for:)`；Linux 上的 Foundation
     不提供 async 版本，需要用 completion handler 桥接。
     */
    private static func loadData(session: URLSession, request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data ?? Data(), response))
            }.resume()
        }
        #else
        return try await session.data(for: request)
        #endif
    }

    /**
     执行请求，对限流与临时性服务端错误做指数退避重试
     */
    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var attempt = 0
        while true {
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await Self.loadData(session: session, request: request)
            } catch {
                if let error = error as? V2exAPIError {
                    throw error
                }
                // 网络层错误同样可重试
                if attempt < maxRetries, isRetryable(networkError: error) {
                    try await backoff(attempt: attempt)
                    attempt += 1
                    continue
                }
                throw V2exAPIError.network(underlying: error)
            }

            if let httpResponse = response as? HTTPURLResponse,
               retryableStatusCodes.contains(httpResponse.statusCode),
               attempt < maxRetries {
                try await backoff(attempt: attempt, response: httpResponse)
                attempt += 1
                continue
            }

            return (data, response)
        }
    }

    /// 指数退避，若服务端给出 X-Rate-Limit-Reset 则优先采用
    private func backoff(attempt: Int, response: HTTPURLResponse? = nil) async throws {
        var delay = retryDelay * pow(2, Double(attempt))
        if let reset = V2exAPIError.intValue(response?.allHeaderFields, "X-Rate-Limit-Reset") {
            let untilReset = Date(timeIntervalSince1970: TimeInterval(reset)).timeIntervalSinceNow
            if untilReset > 0 {
                delay = min(untilReset, 60)
            }
        }
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// 判断网络错误是否值得重试（超时、连接中断、DNS 等）
    private func isRetryable(networkError: any Error) -> Bool {
        guard let urlError = networkError as? URLError else {
            return false
        }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost,
             .notConnectedToInternet, .dnsLookupFailed, .internationalRoamingOff:
            return true
        default:
            return false
        }
    }

    /**
     构造带路径参数的请求路径，对片段做百分号编码，避免非法字符导致 URL 失效
     */
    private func path(_ components: String...) -> String {
        components.map {
            $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? $0
        }.joined(separator: "/")
    }

    /// API 版本对应的基础地址
    ///
    /// V1 与 V2 的主机名不同：V1 是 `v2ex.com`，V2 是 `www.v2ex.com`。
    enum Endpoint {
        /// V1：`https://v2ex.com/api/`
        case v1
        /// V2：`https://www.v2ex.com/api/v2/`
        case v2

        var baseURL: String {
            switch self {
            case .v1:
                return "https://v2ex.com/api/"
            case .v2:
                return "https://www.v2ex.com/api/v2/"
            }
        }
    }
    
    
    // =========== Others ===========

    /**
     获取节点列表
     */
    public func nodesList(fields: [String]? = nil, sortBy: String = "topics", reverse: String = "1") async throws -> [V2Node] {
        let fieldsList = fields ?? ["id", "name", "title", "topics", "aliases"]
        let (data, _) = try await request(
            path: "nodes/list.json",
            args: [
                "fields": fieldsList.joined(separator: ","),
                "sort_by": sortBy,
                "reverse": reverse,
            ],
            decodeClass: [V2Node].self,
            endpoint: .v1
        )
        return data
    }

    // =========== V1 ===========

    /**
     最热主题

     相当于首页右侧的 10 大每天的内容。
     */
    public func hotTopics() async throws -> [V2Topic] {
        let (data, _) = try await request(
            path: "topics/hot.json",
            decodeClass: [V2Topic].self,
            endpoint: .v1
        )
        return data
    }

    /**
     最新主题

     相当于首页的“全部”这个 tab 下的最新内容。
     */
    public func latestTopics() async throws -> [V2Topic] {
        let (data, _) = try await request(
            path: "topics/latest.json",
            decodeClass: [V2Topic].self,
            endpoint: .v1
        )
        return data
    }

    /**
     节点信息

     获得指定节点的名字，简介，URL 及头像图片的地址。

     - parameter  name: 节点名（V2EX 的节点名全是半角英文或者数字）
     */
    public func nodesShow(name: String) async throws -> V2Node {
        let (data, _) = try await request(
            path: "nodes/show.json",
            args: [
                "name": name
            ],
            decodeClass: SingleOrArray<V2Node>.self,
            endpoint: .v1
        )
        guard let node = data.value else {
            throw V2exAPIError.apiFailure(message: "node not found: \(name)", response: nil)
        }
        return node
    }

    /**
     用户主页

     获得指定用户的自我介绍，及其登记的社交网站信息。

     - parameter  username: 用户名
     - parameter  id: 用户在 V2EX 的数字 ID
     */
    public func memberShow(username: String? = nil, id: Int? = nil) async throws -> V2Member {
        var args: [String: String] = [:]
        if let username = username {
            args["username"] = username
        }
        if let id = id {
            args["id"] = String(id)
        }

        if args.isEmpty {
            throw V2exAPIError.invalidURL("members/show.json?username=... or ?id=...")
        }

        let (data, _) = try await request(
            path: "members/show.json",
            args: args,
            decodeClass: SingleOrArray<V2Member>.self,
            endpoint: .v1
        )
        guard let member = data.value else {
            throw V2exAPIError.apiFailure(message: "member not found", response: nil)
        }
        return member
    }

    /**
     获取指定主题下的回复列表

     - parameter  topicId: 主题ID
     */
    public func repliesAll(topicId: Int) async throws -> [V2Comment] {
        let (data, _) = try await request(
            path: "replies/show.json",
            args: [
                "topic_id": topicId
            ],
            decodeClass: [V2Comment].self,
            endpoint: .v1
        )
        return data
    }

    /**
     获取节点下的主题列表（V1）

     - parameter  nodeName: 节点名，如 "swift"
     */
    public func nodeTopics(nodeName: String) async throws -> [V2Topic] {
        let (data, _) = try await request(
            path: "topics/show.json",
            args: [
                "node_name": nodeName
            ],
            decodeClass: [V2Topic].self,
            endpoint: .v1
        )
        return data
    }

    /**
     获取节点下的主题列表（V1）

     与 `nodeTopics(nodeName:)` 等价，保留旧命名以兼容已有调用方。

     - parameter  nodeName: 节点名，如 "swift"
     */
    @available(*, deprecated, renamed: "nodeTopics(nodeName:)")
    public func topics(nodeName: String) async throws -> [V2Topic] {
        try await nodeTopics(nodeName: nodeName)
    }

    // =========== V2 ===========

    /**
     获取指定节点下的主题

     - parameter  nodeName: 节点名，如 "swift"
     - parameter  page: 分页页码，默认为 1
     */
    public func topics(nodeName: String, page: Int = 1) async throws -> V2Response<[V2Topic]?> {
        let (data, _) = try await request(
            path: path("nodes", nodeName, "topics"),
            args: [
                "p": String(page)
            ],
            decodeClass: V2Response<[V2Topic]?>.self
        )
        return data
    }

    /**
     获取指定主题下的回复

     - parameter  topicId: 主题ID
     - parameter  page: 分页页码，默认为 1
     */
    public func replies(topicId: Int, page: Int = 1) async throws -> V2Response<[V2Comment]?> {
        let (data, _) = try await request(
            path: path("topics", String(topicId), "replies"),
            args: [
                "p": String(page)
            ],
            decodeClass: V2Response<[V2Comment]?>.self
        )
        return data
    }

    /**
     获取指定主题

     - parameter  topicId: 主题ID
     */
    public func topic(topicId: Int) async throws -> V2Response<V2Topic?> {
        let (data, _) = try await request(
            path: path("topics", String(topicId)),
            decodeClass: V2Response<V2Topic?>.self
        )
        return data
    }

    /**
     获取指定节点

     - parameter  nodeName: 节点名
     */
    public func getNode(nodeName: String) async throws -> V2Response<V2Node?> {
        let (data, _) = try await request(
            path: path("nodes", nodeName),
            decodeClass: V2Response<V2Node?>.self
        )
        return data
    }

    /**
     获取最新的提醒

     - parameter  page: 分页页码，默认为 1
     */
    public func notifications(page: Int = 1) async throws -> V2Response<[V2Notification]?> {
        let (data, _) = try await request(
            path: "notifications",
            args: [
                "p": String(page)
            ],
            decodeClass: V2Response<[V2Notification]?>.self
        )
        return data
    }

    /**
     删除指定的提醒

     成功时返回 `success: true`，`result` 为空。

     - parameter  notificationId: 提醒ID
     */
    public func deleteNotification(notificationId: Int) async throws -> V2Response<V2EmptyResult> {
        let (data, _) = try await request(
            httpMethod: "DELETE",
            path: path("notifications", String(notificationId)),
            decodeClass: V2Response<V2EmptyResult>.self
        )
        return data
    }

    /**
     获取自己的 Profile
     */
    public func member() async throws -> V2Response<V2Member> {
        let (data, _) = try await request(
            path: "member",
            decodeClass: V2Response<V2Member>.self
        )
        return data
    }

    /**
     查看当前使用的令牌
     */
    public func token() async throws -> V2Response<V2Token> {
        let (data, _) = try await request(
            path: "token",
            decodeClass: V2Response<V2Token>.self
        )
        return data
    }

    /**
     创建新的令牌

     你可以在系统中最多创建 10 个 Personal Access Token。

     - parameter  scope: 可选 everything 或者 regular，如果是 regular 类型的 Token 将不能用于进一步创建新的 token
     - parameter  expiration: 可支持的值：2592000，5184000，7776000 或者 15552000，即 30 天，60 天，90 天或者 180 天的秒数
     */
    public func createToken(expiration: Int, scope: String? = nil) async throws -> V2Response<V2Token> {
        var args: [String: Any] = ["expiration": expiration]
        if let scope = scope {
            args["scope"] = scope
        }

        let (data, _) = try await request(
            httpMethod: "POST",
            path: "token",
            args: args,
            decodeClass: V2Response<V2Token>.self
        )
        return data
    }
}
