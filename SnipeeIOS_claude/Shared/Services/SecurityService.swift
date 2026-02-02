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

    private init() {}

    // MARK: - Token Management

    func saveTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)

        let expiry = Date().addingTimeInterval(expiresIn)
        UserDefaults.standard.set(expiry, forKey: tokenExpiryKey)

        // Set session expiry (30 days)
        let sessionExpiry = Date().addingTimeInterval(30 * 24 * 60 * 60)
        UserDefaults.standard.set(sessionExpiry, forKey: sessionExpiryKey)
    }

    func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }

    func isTokenExpired() -> Bool {
        guard let expiry = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date else {
            return true
        }
        return Date() > expiry
    }

    func isSessionExpired() -> Bool {
        guard let expiry = UserDefaults.standard.object(forKey: sessionExpiryKey) as? Date else {
            return true
        }
        return Date() > expiry
    }

    func isLoggedIn() -> Bool {
        return getAccessToken() != nil && !isSessionExpired()
    }

    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiryKey)
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        SecItemAdd(newQuery as CFDictionary, nil)
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
