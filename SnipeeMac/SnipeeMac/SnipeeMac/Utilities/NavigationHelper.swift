//
//  NavigationHelper.swift
//  SnipeeMac
//

import Foundation

enum NavigationHelper {
    /// カーソル移動（ループ対応）
    /// - Parameters:
    ///   - current: 現在のインデックス
    ///   - delta: 移動量（-1: 上, +1: 下）
    ///   - count: 総アイテム数
    /// - Returns: 新しいインデックス
    static func loopIndex(_ current: Int, delta: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (current + delta + count) % count
    }
}
