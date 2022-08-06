//
//  File.swift
//
//
//  Created by isaced on 2022/7/24.
//

import Foundation

/// V2EX API Response
public struct V2Response<T: Decodable>: Decodable {
  public let success: Bool
  public let message: String?
  public let result: T?
}
