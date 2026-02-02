//
//  SecurityService.swift
//  SnipeeIOS
//

import Foundation
import Security

class SecurityService {
    static let shared = SecurityService()

    private let serviceName = "com.addness.snipee"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let tokenExpiryKey = "tokenExpiry"
    private let sessionExpiryKey = "sessionExpiry"
    private let setupCompletedKey = "setupCompleted"

    private init() {
        print("📱 [Security] init()")
    }

    // MARK: - Token Management

    func saveTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        print("📱 [Security] saveTokens() 開始")
        print("📱 [Security] アクセストークン: \(accessToken.prefix(20))...")
        print("📱 [Security] リフレッシュトークン: \(refreshToken.isEmpty ? "なし" : String(refreshToken.prefix(20)) + "...")")

        saveToKeychain(key: accessTokenKey, value: accessToken)
        if !refreshToken.isEmpty {
            saveToKeychain(key: refreshTokenKey, value: refreshToken)
        }

        let expiry = Date().addingTimeInterval(expiresIn)
        UserDefaults.standard.set(expiry, forKey: tokenExpiryKey)
        print("📱 [Security] トークン有効期限: \(expiry)")

        // Set session expiry (30 days)
        let sessionExpiry = Date().addingTimeInterval(30 * 24 * 60 * 60)
        UserDefaults.standard.set(sessionExpiry, forKey: sessionExpiryKey)

        print("✅ [Security] saveTokens() 完了")
    }

    func getAccessToken() -> String? {
        let token = getFromKeychain(key: accessTokenKey)
        print("📱 [Security] getAccessToken(): \(token != nil ? "あり" : "なし")")
        return token
    }

    func getRefreshToken() -> String? {
        let token = getFromKeychain(key: refreshTokenKey)
        print("📱 [Security] getRefreshToken(): \(token != nil ? "あり" : "なし")")
        return token
    }

    func isTokenExpired() -> Bool {
        guard let expiry = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date else {
            print("📱 [Security] isTokenExpired(): true（有効期限なし）")
            return true
        }
        let expired = Date() > expiry
        print("📱 [Security] isTokenExpired(): \(expired) (期限: \(expiry))")
        return expired
    }

    func isSessionExpired() -> Bool {
        guard let expiry = UserDefaults.standard.object(forKey: sessionExpiryKey) as? Date else {
            return true
        }
        return Date() > expiry
    }

    func isLoggedIn() -> Bool {
        let loggedIn = getAccessToken() != nil && !isSessionExpired()
        print("📱 [Security] isLoggedIn(): \(loggedIn)")
        return loggedIn
    }

    func clearTokens() {
        print("📱 [Security] clearTokens() 実行")
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiryKey)
        print("✅ [Security] clearTokens() 完了")
    }

    // MARK: - Setup Management

    func completeSetup() {
        UserDefaults.standard.set(true, forKey: setupCompletedKey)
        print("✅ [Security] セットアップ完了フラグ設定")
    }

    func isSetupCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: setupCompletedKey)
    }

    // MARK: - Logout

    func logout() {
        print("📱 [Security] logout() 実行")
        clearTokens()
        StorageService.shared.clearAllData()
        UserDefaults.standard.removeObject(forKey: setupCompletedKey)
        print("✅ [Security] logout() 完了")
    }

    // MARK: - Membership Validation

    func validateMembership() async -> Bool {
        // Check if user email is in the members list
        guard let email = GoogleAuthService.shared.currentUserEmail else {
            print("❌ [Security] validateMembership(): メールなし")
            return false
        }

        print("✅ [Security] validateMembership(): \(email)")
        return !email.isEmpty
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else {
            print("❌ [Security] Keychain保存失敗: データ変換エラー")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newQuery as CFDictionary, nil)
        if status == errSecSuccess {
            print("✅ [Security] Keychain保存成功: \(key)")
        } else {
            print("❌ [Security] Keychain保存失敗: \(key), status=\(status)")
        }
    }

    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
