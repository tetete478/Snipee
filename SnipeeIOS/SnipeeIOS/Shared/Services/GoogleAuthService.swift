//
//  GoogleAuthService.swift
//  SnipeeIOS
//

import Foundation
import AuthenticationServices
import UIKit

class GoogleAuthService: NSObject {
    static let shared = GoogleAuthService()

    private let clientId = "366174659528-uhgbhpsc81erb6ki1qcbkm68h777sudn.apps.googleusercontent.com"
    private let redirectUri = "com.addness.snipee:/oauth2callback"
    private let scopes = [
        "https://www.googleapis.com/auth/drive",          // Mac版と同じ（全ファイルアクセス）
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/userinfo.email"
    ]

    private var authSession: ASWebAuthenticationSession?
    private weak var presentationAnchor: ASPresentationAnchor?

    private let userEmailKey = "currentUserEmail"

    var currentUserEmail: String? {
        get { UserDefaults.standard.string(forKey: userEmailKey) }
        set { UserDefaults.standard.set(newValue, forKey: userEmailKey) }
    }

    private override init() {
        super.init()
    }

    // MARK: - Async/Await API

    @MainActor
    func signIn() async throws {
        print("📱 [GoogleAuth] signIn() 開始")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ [GoogleAuth] ウィンドウが見つかりません")
                continuation.resume(throwing: AuthError.noWindow)
                return
            }

            login(from: window) { result in
                switch result {
                case .success:
                    print("✅ [GoogleAuth] ログイン成功（トークン取得完了）")
                    continuation.resume()
                case .failure(let error):
                    print("❌ [GoogleAuth] ログイン失敗: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }

        // Fetch user email after successful login
        print("📱 [GoogleAuth] ユーザー情報取得中...")
        try await fetchUserEmail()
        print("✅ [GoogleAuth] ユーザーメール: \(currentUserEmail ?? "nil")")
    }

    func signOut() {
        print("📱 [GoogleAuth] signOut() 実行")
        logout()
    }

    func isSignedIn() -> Bool {
        let hasToken = SecurityService.shared.getAccessToken() != nil
        print("📱 [GoogleAuth] isSignedIn: \(hasToken)")
        return hasToken
    }

    // MARK: - Callback-based API

    func login(from anchor: ASPresentationAnchor, completion: @escaping (Result<Void, Error>) -> Void) {
        print("📱 [GoogleAuth] login() 開始")
        presentationAnchor = anchor

        let scopeString = scopes.joined(separator: " ")
        let authUrl = "https://accounts.google.com/o/oauth2/v2/auth?" +
            "client_id=\(clientId)" +
            "&redirect_uri=\(redirectUri)" +
            "&response_type=code" +
            "&scope=\(scopeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" +
            "&access_type=offline" +
            "&prompt=consent"

        guard let url = URL(string: authUrl) else {
            print("❌ [GoogleAuth] 認証URL生成失敗")
            completion(.failure(AuthError.invalidURL))
            return
        }

        print("📱 [GoogleAuth] 認証セッション開始...")
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.addness.snipee"
        ) { [weak self] callbackURL, error in
            if let error = error {
                print("❌ [GoogleAuth] 認証セッションエラー: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let callbackURL = callbackURL,
                  let code = self?.extractCode(from: callbackURL) else {
                print("❌ [GoogleAuth] 認証コード取得失敗")
                completion(.failure(AuthError.noAuthCode))
                return
            }

            print("✅ [GoogleAuth] 認証コード取得成功")
            self?.exchangeCodeForTokens(code: code, completion: completion)
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    func refreshTokenIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        print("📱 [GoogleAuth] refreshTokenIfNeeded() チェック中...")

        guard SecurityService.shared.isTokenExpired() else {
            print("✅ [GoogleAuth] トークン有効")
            completion(.success(()))
            return
        }

        guard let refreshToken = SecurityService.shared.getRefreshToken() else {
            print("❌ [GoogleAuth] リフレッシュトークンなし")
            completion(.failure(AuthError.notAuthenticated))
            return
        }

        print("📱 [GoogleAuth] トークンリフレッシュ中...")
        refreshAccessToken(refreshToken: refreshToken, completion: completion)
    }

    func logout() {
        currentUserEmail = nil
        SecurityService.shared.clearTokens()
        StorageService.shared.clearAllData()
        print("✅ [GoogleAuth] ログアウト完了")
    }

    // MARK: - Private Methods

    private func extractCode(from url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }

    private func exchangeCodeForTokens(code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("📱 [GoogleAuth] トークン交換中...")
        let tokenUrl = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "client_id=\(clientId)" +
            "&code=\(code)" +
            "&grant_type=authorization_code" +
            "&redirect_uri=\(redirectUri)"

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [GoogleAuth] トークン交換ネットワークエラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                print("❌ [GoogleAuth] トークン交換データなし")
                DispatchQueue.main.async { completion(.failure(AuthError.invalidResponse)) }
                return
            }

            // デバッグ: レスポンス内容を出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 [GoogleAuth] トークンレスポンス: \(responseString.prefix(500))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                print("❌ [GoogleAuth] アクセストークン解析失敗")
                DispatchQueue.main.async { completion(.failure(AuthError.invalidResponse)) }
                return
            }

            let refreshToken = json["refresh_token"] as? String
            let expiresIn = json["expires_in"] as? TimeInterval ?? 3600

            print("✅ [GoogleAuth] アクセストークン取得成功")
            print("📱 [GoogleAuth] リフレッシュトークン: \(refreshToken != nil ? "あり" : "なし")")

            SecurityService.shared.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken ?? SecurityService.shared.getRefreshToken() ?? "",
                expiresIn: expiresIn
            )

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    private func refreshAccessToken(refreshToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let tokenUrl = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "client_id=\(clientId)" +
            "&refresh_token=\(refreshToken)" +
            "&grant_type=refresh_token"

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [GoogleAuth] トークンリフレッシュエラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? TimeInterval else {
                print("❌ [GoogleAuth] トークンリフレッシュ解析失敗")
                DispatchQueue.main.async { completion(.failure(AuthError.invalidResponse)) }
                return
            }

            print("✅ [GoogleAuth] トークンリフレッシュ成功")

            SecurityService.shared.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    private func fetchUserEmail() async throws {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let responseString = String(data: data, encoding: .utf8) {
            print("📱 [GoogleAuth] ユーザー情報レスポンス: \(responseString)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let email = json["email"] as? String {
            currentUserEmail = email
        }
    }
}

extension GoogleAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationAnchor ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

enum AuthError: Error, LocalizedError {
    case invalidURL
    case noAuthCode
    case invalidResponse
    case noWindow
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .noAuthCode: return "認証コードがありません"
        case .invalidResponse: return "無効なレスポンスです"
        case .noWindow: return "ウィンドウがありません"
        case .notAuthenticated: return "認証されていません"
        }
    }
}
