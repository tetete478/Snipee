
//
//  Constants.swift
//  SnipeeMac
//

import Foundation
import AppKit

enum Constants {
    enum App {
        static let name = "Snipee"
        static let bundleId = "com.addness.SnipeeMac"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    enum Google {
        static let clientId = "366174659528-of1spk0m9ohhd3kldc5fkbd5rdd73916.apps.googleusercontent.com"
        static let redirectUri = "com.addness.snipeemac:/oauth2callback"
        static let scopes = [
            "https://www.googleapis.com/auth/spreadsheets.readonly",
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/drive.file",
            "https://www.googleapis.com/auth/userinfo.email"
        ]
    }
    
    enum Sparkle {
        static let appcastURL = "https://tetete478.github.io/snipee/appcast-mac.xml"
    }
    
    enum Keychain {
        static let service = "com.addness.SnipeeMac"
        static let accessToken = "google_access_token"
        static let refreshToken = "google_refresh_token"
        static let userEmail = "user_email"
    }
    
    enum UI {
        static let popupWidth: CGFloat = 180
        static let popupMaxHeight: CGFloat = 500
        static let submenuWidth: CGFloat = 280
        static let submenuMaxHeight: CGFloat = 650
        static let expandedPopupWidth: CGFloat = 470
        
        static func configurePopupPanel(_ panel: NSPanel) {
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isMovableByWindowBackground = true
        }
        
        static func configureModalWindow(_ window: NSWindow) {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
        }
    }
    
    enum History {
        static let maxCount = 100
        static let groupSize = 15
    }
    
    enum FontSize {
        static let small: CGFloat = 11    // 注釈
        static let caption: CGFloat = 12    // セクション、カウント、説明
        static let body: CGFloat = 13       // メニューアイテム、本文
        static let title: CGFloat = 16      // 見出し
        static let large: CGFloat = 20      // 大見出し
    }
}
