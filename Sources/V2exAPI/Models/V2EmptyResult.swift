//
//  V2EmptyResult.swift
//

import Foundation

/// 没有返回体的接口的成功占位
///
/// 用于 `deleteNotification` 这类只返回 `{"success": true}` 的接口。
/// 解码时忽略所有字段，因此服务端返回 `result: null`、`result: {}`
/// 或者完全不返回 `result` 都能成功。
public struct V2EmptyResult: Decodable, Hashable, Sendable {

    /// 创建一个空的占位结果
    public init() {}

    /// 忽略任何输入，始终创建成功
    public init(from decoder: any Decoder) throws {
        // 接受任意形态（object / null / 缺失），仅用于表达「无返回体」
    }
}
