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
public struct V2Notification: Decodable {
    let id, memberID, forMemberID: Int
    let text, payload, payloadRendered: String
    let created: Int
    let member: V2Member

    enum CodingKeys: String, CodingKey {
        case id
        case memberID = "member_id"
        case forMemberID = "for_member_id"
        case text, payload
        case payloadRendered = "payload_rendered"
        case created, member
    }
}
