//
//  V2Token.swift
//  
//
//  Created by isaced on 2022/8/7.
//

import Foundation

/**
 Token
 */
public struct V2Token: Decodable {
    let token, scope: String
    let expiration, goodForDays, totalUsed, lastUsed: Int
    let created: Int

    enum CodingKeys: String, CodingKey {
        case token, scope, expiration
        case goodForDays = "good_for_days"
        case totalUsed = "total_used"
        case lastUsed = "last_used"
        case created
    }
}
