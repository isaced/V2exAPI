import XCTest

@testable import V2exAPI

final class V2exAPITests: XCTestCase {
    
    func testAPI() async throws {
        let v2ex = V2exAPI()
        
        let nodes = try? await v2ex.nodesList()
        XCTAssertNotNil(nodes)
        
        let latest = try await v2ex.latestTopics()
        XCTAssertNotNil(latest)
        
        let hot = try await v2ex.hotTopics()
        XCTAssertNotNil(hot)
        
        let nodeDetail = try await v2ex.nodesShow(name: "swift")
        XCTAssertNotNil(nodeDetail)
        
        let member = try await v2ex.memberShow(username: "isaced")
        XCTAssertNotNil(member)
        
        let repliesAll = try await v2ex.repliesAll(topicId: 883252)
        XCTAssertNotNil(repliesAll)
        
        let topics = try await v2ex.topics(nodeName: "apple")
        XCTAssertNotNil(topics)
        
        // --- V2 ---
        
        //        let topics = try await v2ex.topics(nodeName: "swift")
        //        XCTAssertNotNil(topics)
        //
        //        let topic = try await v2ex.topic(topicId: 870607)
        //        XCTAssertNotNil(topic)
        //
        //        let node = try await v2ex.getNode(nodeName: "swift")
        //        XCTAssertNotNil(node)
        //
        //        let notifications = try await v2ex.notifications()
        //        XCTAssertNotNil(notifications)
        //
        //        let delNotifications = try await v2ex.deleteNotification(notificationId: 5846288)
        //        XCTAssertNotNil(delNotifications)
        //
        //        let memberMe = try await v2ex.member()
        //        XCTAssertNotNil(memberMe)
    }
    
}
