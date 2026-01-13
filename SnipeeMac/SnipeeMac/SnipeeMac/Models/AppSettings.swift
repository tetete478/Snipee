
//
//  AppSettings.swift
//  SnipeeMac
//

import Foundation

struct HotkeyConfig: Codable {
    var keyCode: UInt16
    var modifiers: UInt
    
    init(keyCode: UInt16 = 8, modifiers: UInt = 0) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

struct AppSettings: Codable {
    var userName: String
    var historyMaxCount: Int
    var autoLogin: Bool
    var theme: String
    var hotkeyMain: HotkeyConfig
    var hotkeySnippet: HotkeyConfig
    var hotkeyHistory: HotkeyConfig
    var pasteDelay: Int
    var lastSyncDate: Date?
    
    init() {
        self.userName = ""
        self.historyMaxCount = 100
        self.autoLogin = true
        self.theme = "silver"
        self.hotkeyMain = HotkeyConfig(keyCode: 8, modifiers: 0x40101)     // Cmd+Ctrl+C
        self.hotkeySnippet = HotkeyConfig(keyCode: 9, modifiers: 0x40101) // Cmd+Ctrl+V
        self.hotkeyHistory = HotkeyConfig(keyCode: 7, modifiers: 0x40101) // Cmd+Ctrl+X
        self.pasteDelay = 50
        self.lastSyncDate = nil
    }
}
