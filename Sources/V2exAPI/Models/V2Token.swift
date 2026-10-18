//
//  V2Token.swift
//
//
//  Created by isaced on 2022/8/7.
//

import Foundation

/// 个人访问令牌（Personal Access Token）
///
/// 对应 V2 的 `GET /token` 与 `POST /token` 接口。
/// 申请与管理的说明见 <https://v2ex.com/help/personal-access-token>。
public struct V2Token: Decodable, Equatable, Hashable, Sendable {

    /// 令牌字符串，形如 `XXXXX-XXXX-XXXX-XXXX-XXXXXXXXX`
    public let token: String?

    /// 权限范围：`everything` 或 `regular`
    ///
    /// `regular` 类型的令牌不能再用于创建新的令牌。
    public let scope: String?

    /// 过期时间（Unix 时间戳，秒）
    public let expiration: Int?

    /// 距离过期还有多少天
    public let goodForDays: Int?

    /// 累计使用次数
    public let totalUsed: Int?

    /// 最近一次使用时间（Unix 时间戳，秒）
    public let lastUsed: Int?

    /// 创建时间（Unix 时间戳，秒）
    public let created: Int?

    enum CodingKeys: String, CodingKey {
        case token, scope, expiration
        case goodForDays = "good_for_days"
        case totalUsed = "total_used"
        case lastUsed = "last_used"
        case created
    }
}
