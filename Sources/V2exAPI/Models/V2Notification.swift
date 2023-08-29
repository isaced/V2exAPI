//
//  V2Notification.swift
//  
//
//  Created by isaced on 2022/8/7.
//

import Foundation

/**
 通知
 */
public struct V2Notification: Decodable, Identifiable, Hashable {
    public let id, memberID, forMemberID: Int?
    public let text, payload, payloadRendered: String?
    public let created: Int?
    public let member: V2Member?
    
    enum CodingKeys: String, CodingKey {
        case id
        case memberID = "member_id"
        case forMemberID = "for_member_id"
        case text, payload
        case payloadRendered = "payload_rendered"
        case created, member
    }
}
