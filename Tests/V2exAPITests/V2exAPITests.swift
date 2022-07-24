import XCTest

@testable import V2exAPI

final class V2exAPITests: XCTestCase {

  func testAPI() async throws {
    let v2ex = V2exAPI(accessToken: "")

    let nodes = try await v2ex.nodesList()
    XCTAssertNotNil(nodes)

    let latest = try await v2ex.latestTopics()
    XCTAssertNotNil(latest)

    let topics = try await v2ex.topics(nodeName: "swift")
    XCTAssertNotNil(topics)
  }

}
