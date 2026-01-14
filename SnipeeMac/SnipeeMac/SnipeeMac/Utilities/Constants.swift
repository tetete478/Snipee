
//
//  Constants.swift
//  SnipeeMac
//

import Foundation

enum Constants {
    enum App {
        static let name = "Snipee"
        static let bundleId = "com.addness.SnipeeMac"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    enum Google {
        static let clientId = ""  // .env から読み込み予定
        static let clientSecret = ""  // .env から読み込み予定
        static let redirectUri = "com.addness.snipeemac:/oauth2callback"
        static let scopes = [
            "https://www.googleapis.com/auth/spreadsheets.readonly",
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/drive.file",
            "https://www.googleapis.com/auth/userinfo.email"
        ]
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
    }
    
    enum History {
        static let maxCount = 100
        static let groupSize = 15
    }
}
