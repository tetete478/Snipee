//
//  PopupKeyboardHandler.swift
//  SnipeeMac
//
//  共通キーボードハンドリング

import Foundation

/// ポップアップメニュー共通のキーボード処理
struct PopupKeyboardHandler {

    // MARK: - Key Codes

    static let keyUp: UInt16 = 126
    static let keyDown: UInt16 = 125
    static let keyRight: UInt16 = 124
    static let keyLeft: UInt16 = 123
    static let keyEnter: UInt16 = 36
    static let keyP: UInt16 = 35

    // MARK: - Main Menu Navigation

    /// メインメニューの上移動（ループ）
    static func navigateUp(from index: Int, count: Int) -> Int {
        NavigationHelper.loopIndex(index, delta: -1, count: count)
    }

    /// メインメニューの下移動（ループ）
    static func navigateDown(from index: Int, count: Int) -> Int {
        NavigationHelper.loopIndex(index, delta: 1, count: count)
    }

    // MARK: - Submenu Navigation

    /// サブメニューの上移動（ループ）
    static func submenuNavigateUp(from index: Int, count: Int) -> Int {
        index > 0 ? index - 1 : count - 1
    }

    /// サブメニューの下移動（ループ）
    static func submenuNavigateDown(from index: Int, count: Int) -> Int {
        index < count - 1 ? index + 1 : 0
    }

    // MARK: - Number Keys

    /// 数字キー(1-9)のキーコードから番号を取得
    /// - Returns: 1-9の数字、または該当なしの場合nil
    static func numberFromKeyCode(_ keyCode: UInt16) -> Int? {
        keyCode >= 101 && keyCode <= 109 ? Int(keyCode) - 100 : nil
    }

    // MARK: - Generic Handlers

    /// メインメニューのキーハンドリング
    /// - Parameters:
    ///   - keyCode: キーコード
    ///   - selectedIndex: 現在の選択インデックス（更新される）
    ///   - totalCount: 選択可能な項目数
    ///   - onRight: 右キー押下時のアクション
    ///   - onEnter: Enterキー押下時のアクション
    ///   - onNumberKey: 数字キー押下時のアクション（番号が渡される）
    ///   - customHandler: カスタムキーハンドラー（処理した場合true）
    /// - Returns: キーが処理された場合true
    static func handleMainMenu(
        keyCode: UInt16,
        selectedIndex: inout Int,
        totalCount: Int,
        onRight: () -> Void,
        onEnter: () -> Void,
        onNumberKey: ((Int) -> Void)? = nil,
        customHandler: ((UInt16) -> Bool)? = nil
    ) -> Bool {
        switch keyCode {
        case keyUp:
            selectedIndex = navigateUp(from: selectedIndex, count: totalCount)
            return true
        case keyDown:
            selectedIndex = navigateDown(from: selectedIndex, count: totalCount)
            return true
        case keyRight:
            onRight()
            return true
        case keyEnter:
            onEnter()
            return true
        default:
            // カスタムハンドラーを先に試す
            if let handler = customHandler, handler(keyCode) {
                return true
            }
            // 数字キー処理
            if let num = numberFromKeyCode(keyCode), let handler = onNumberKey {
                handler(num)
                return true
            }
            return false
        }
    }

    /// サブメニューのキーハンドリング
    /// - Parameters:
    ///   - keyCode: キーコード
    ///   - selectedIndex: 現在の選択インデックス（更新される）
    ///   - itemCount: サブメニュー項目数
    ///   - onClose: 左キー押下時のアクション（サブメニューを閉じる）
    ///   - onEnter: Enterキー押下時のアクション
    ///   - onNumberKey: 数字キー押下時のアクション（番号が渡される）
    ///   - customHandler: カスタムキーハンドラー（処理した場合true）
    /// - Returns: キーが処理された場合true
    static func handleSubmenu(
        keyCode: UInt16,
        selectedIndex: inout Int,
        itemCount: Int,
        onClose: () -> Void,
        onEnter: () -> Void,
        onNumberKey: ((Int) -> Void)? = nil,
        customHandler: ((UInt16) -> Bool)? = nil
    ) -> Bool {
        switch keyCode {
        case keyUp:
            selectedIndex = submenuNavigateUp(from: selectedIndex, count: itemCount)
            return true
        case keyDown:
            selectedIndex = submenuNavigateDown(from: selectedIndex, count: itemCount)
            return true
        case keyLeft:
            onClose()
            return true
        case keyEnter:
            onEnter()
            return true
        default:
            // カスタムハンドラーを先に試す
            if let handler = customHandler, handler(keyCode) {
                return true
            }
            // 数字キー処理
            if let num = numberFromKeyCode(keyCode), let handler = onNumberKey {
                handler(num)
                return true
            }
            return false
        }
    }
}
