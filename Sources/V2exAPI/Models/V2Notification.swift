//
//  V2Notification.swift
//
//
//  Created by isaced on 2022/8/7.
//

import Foundation

/// 提醒（通知）
///
/// 对应 V2 的 `GET /notifications` 接口，需要有效的访问令牌。
public struct V2Notification: Decodable, Identifiable, Hashable, Sendable {

    /// 提醒 ID，用于 `deleteNotification(notificationId:)`
    public let id: Int?

    /// 触发该提醒的成员 ID
    public let memberID: Int?

    /// 收到该提醒的成员 ID
    public let forMemberID: Int?

    /// 提醒的纯文本内容
    public let text: String?

    /// 未经渲染的原文（通常是 Markdown）
    public let payload: String?

    /// 已渲染为 HTML 的内容
    public let payloadRendered: String?

    /// 创建时间（Unix 时间戳，秒）
    public let created: Int?

    /// 触发该提醒的成员
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
