//
//  GoogleAuthService.swift
//  SnipeeMac
//

@preconcurrency import Foundation
import AppKit
import CryptoKit

class GoogleAuthService {
    static let shared = GoogleAuthService()
    
    private var codeVerifier: String?
    private var authCompletion: ((Result<String, Error>) -> Void)?
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let userEmail = "userEmail"
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    var isLoggedIn: Bool {
        defaults.string(forKey: Keys.accessToken) != nil
    }
    
    var userEmail: String? {
        defaults.string(forKey: Keys.userEmail)
    }
    
    func startOAuthFlow(completion: @escaping (Result<String, Error>) -> Void) {
        authCompletion = completion
        
        // Generate PKCE code verifier and challenge
        codeVerifier = generateCodeVerifier()
        guard let verifier = codeVerifier,
              let challenge = generateCodeChallenge(from: verifier) else {
            completion(.failure(AuthError.pkceGenerationFailed))
            return
        }
        
        // Build authorization URL
        let scopes = Constants.Google.scopes.joined(separator: " ")
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.Google.clientId),
            URLQueryItem(name: "redirect_uri", value: Constants.Google.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "hd", value: "team.addness.co.jp"),
            URLQueryItem(name: "login_hint", value: "@team.addness.co.jp")
        ]
        
        guard let url = components.url else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        // Open browser
        NSWorkspace.shared.open(url)
    }
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            authCompletion?(.failure(AuthError.noCodeInCallback))
            return
        }
        
        exchangeCodeForTokens(code: code)
    }
    
    func logout() {
        defaults.removeObject(forKey: Keys.accessToken)
        defaults.removeObject(forKey: Keys.refreshToken)
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: "userName")
        defaults.removeObject(forKey: "userDepartment")
        defaults.removeObject(forKey: "userRole")
    }
    
    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        if let token = defaults.string(forKey: Keys.accessToken) {
            completion(.success(token))
            return
        }
        
        // Try refresh
        if let refreshToken = defaults.string(forKey: Keys.refreshToken) {
            refreshAccessToken(refreshToken: refreshToken, completion: completion)
            return
        }
        
        completion(.failure(AuthError.notLoggedIn))
    }
    
    // MARK: - Private Methods
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
    
    private func exchangeCodeForTokens(code: String) {
        guard let verifier = codeVerifier else {
            authCompletion?(.failure(AuthError.noCodeVerifier))
            return
        }
        
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "client_id": Constants.Google.clientId,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": Constants.Google.redirectUri
        ]
        
        request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.authCompletion?(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.authCompletion?(.failure(AuthError.noData))
                }
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                
                // Save tokens
                self?.defaults.set(tokenResponse.accessToken, forKey: Keys.accessToken)
                if let refreshToken = tokenResponse.refreshToken {
                    self?.defaults.set(refreshToken, forKey: Keys.refreshToken)
                }
                
                // Fetch user email, then complete
                self?.fetchUserEmail(accessToken: tokenResponse.accessToken) {
                    self?.authCompletion?(.success(tokenResponse.accessToken))
                }
            } catch {
                DispatchQueue.main.async {
                    self?.authCompletion?(.failure(error))
                }
            }
        }.resume()
    }
    
    private func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "client_id": Constants.Google.clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(AuthError.noData))
                }
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                self?.defaults.set(tokenResponse.accessToken, forKey: Keys.accessToken)
                
                DispatchQueue.main.async {
                    completion(.success(tokenResponse.accessToken))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func fetchUserEmail(accessToken: String, completion: @escaping () -> Void) {
        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let data = data,
               let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
                self?.defaults.set(userInfo.email, forKey: Keys.userEmail)
            }
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
}

// MARK: - Error Types

enum AuthError: Error, LocalizedError {
    case pkceGenerationFailed
    case invalidURL
    case noCodeInCallback
    case noCodeVerifier
    case noData
    case notLoggedIn
    
    var errorDescription: String? {
        switch self {
        case .pkceGenerationFailed: return "PKCE生成に失敗しました"
        case .invalidURL: return "無効なURLです"
        case .noCodeInCallback: return "認証コードがありません"
        case .noCodeVerifier: return "コード検証器がありません"
        case .noData: return "データがありません"
        case .notLoggedIn: return "ログインしていません"
        }
    }
}

// MARK: - Response Models

struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct UserInfo: Codable, Sendable {
    let email: String
    let name: String?
}

// MARK: - Data Extension

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
