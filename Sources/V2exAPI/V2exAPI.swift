import Foundation

/// V2ex API
public struct V2exAPI {

  /**
   个人访问令牌

   生成参考： https://v2ex.com/help/personal-access-token
   */
  public var accessToken: String?

  private let endpointV1 = "https://v2ex.com/api/"
  private let endpointV2 = "https://www.v2ex.com/api/v2/"

  public init(accessToken: String? = nil) {
    self.accessToken = accessToken
  }

  /**
   HTTP GET 请求
   */
  private func httpGet(url: String, args: [String: String]? = nil) async throws -> (
    Data?, URLResponse?
  ) {
    let urlComponents = NSURLComponents(string: url)!

    if args != nil {
      urlComponents.queryItems =
        args?.map({ (k, v) in
          return NSURLQueryItem(name: k, value: v)
        }) as [URLQueryItem]?
    }

    guard let requestUrl = urlComponents.url else {
      return (nil, nil)
    }

    var request = URLRequest(url: requestUrl)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    if let accessToken = accessToken {
      request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    }
    let (data, response) = try await URLSession.shared.data(for: request)
    return (data, response)
  }

  /**
   获取节点列表
   */
  public func nodesList() async throws -> [V2Node]? {
    let (data, _) = try await httpGet(
      url: endpointV1 + "nodes/list.json",
      args: [
        "fields": "id,name,title,topics,aliases",
        "sort_by": "topics",
        "reverse": "1",
      ])
    guard let data = data else {
      return nil
    }

    let decoder = JSONDecoder()
    return try decoder.decode([V2Node].self, from: data)
  }

  /**
   最新主题：相当于首页的“全部”这个 tab 下的最新内容。
   */
  public func latestTopics() async throws -> [V2Topic]? {
    let (data, _) = try await httpGet(url: endpointV1 + "topics/latest.json")
    guard let data = data else {
      return nil
    }

    let decoder = JSONDecoder()
    return try decoder.decode([V2Topic].self, from: data)
  }

  /**
   获取指定节点下的主题

   - parameter  nodeName: 节点名，如 "swift"
   - parameter  page: 分页页码，默认为 1
   */
  public func topics(nodeName: String, page: Int = 1) async throws -> V2Response<[V2Topic]?>? {
    let path = "nodes/\(nodeName)/topics"
    let (data, _) = try await httpGet(
      url: endpointV2 + path,
      args: [
        "p": String(page)
      ])
    guard let data = data else {
      return nil
    }

    let decoder = JSONDecoder()
    return try decoder.decode(V2Response<[V2Topic]?>.self, from: data)
  }
}
