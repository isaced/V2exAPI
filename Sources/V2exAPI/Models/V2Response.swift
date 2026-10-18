//
//  V2Response.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// V2EX API Response
///
/// `result` 为可选：部分接口（如删除提醒）成功时不会返回 `result` 字段，
/// 或返回 `null`。调用方仍应通过 `success` 判断业务是否成功。
public struct V2Response<T: Decodable>: Decodable {
    public let success: Bool
    public let message: String?
    public let result: T?

    public init(success: Bool, message: String? = nil, result: T? = nil) {
        self.success = success
        self.message = message
        self.result = result
    }
}

/// 仅用于解析错误响应体中的 `message` / `error` 字段
struct V2exAPIFailure: Decodable {
    let message: String?
    let error: String?
}
