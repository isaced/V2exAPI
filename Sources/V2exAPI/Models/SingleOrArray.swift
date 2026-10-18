//
//  SingleOrArray.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// V1 接口的兼容解码器
///
/// 部分 V1 接口（如 `nodes/show.json`、`members/show.json`）在不同时期
/// 分别返回过单个对象或单元素数组。这里统一兼容两种形态：
/// 优先按数组解出第一个元素，失败时再按单对象解码。
struct SingleOrArray<T: Decodable>: Decodable {

    let value: T?

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let array = try? container.decode([T].self) {
            value = array.first
        } else {
            value = try container.decode(T.self)
        }
    }
}
