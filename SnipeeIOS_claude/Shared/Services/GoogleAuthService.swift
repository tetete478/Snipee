//
//  GoogleAuthService.swift
//  SnipeeIOS
//

import Foundation
import AuthenticationServices

class GoogleAuthService: NSObject {
    static let shared = GoogleAuthService()

    private let clientId = "YOUR_CLIENT_ID"
    private let redirectUri = "com.addness.snipee:/oauth2callback"
    private let scopes = [
        "https://www.googleapis.com/auth/drive.file",
        "https://www.googleapis.com/auth/spreadsheets"
    ]

    private var authSession: ASWebAuthenticationSession?
    private weak var presentationAnchor: ASPresentationAnchor?

    private override init() {
        super.init()
    }

    func login(from anchor: ASPresentationAnchor, completion: @escaping (Result<Void, Error>) -> Void) {
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
            completion(.failure(AuthError.invalidURL))
            return
        }

        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.addness.snipee"
        ) { [weak self] callbackURL, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let callbackURL = callbackURL,
                  let code = self?.extractCode(from: callbackURL) else {
                completion(.failure(AuthError.noAuthCode))
                return
            }

            self?.exchangeCodeForTokens(code: code, completion: completion)
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    func refreshTokenIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        guard SecurityService.shared.isTokenExpired(),
              let refreshToken = SecurityService.shared.getRefreshToken() else {
            completion(.success(()))
            return
        }

        refreshAccessToken(refreshToken: refreshToken, completion: completion)
    }

    func logout() {
        SecurityService.shared.clearTokens()
        StorageService.shared.clearAllData()
    }

    // MARK: - Private Methods

    private func extractCode(from url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }

    private func exchangeCodeForTokens(code: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String,
                  let expiresIn = json["expires_in"] as? TimeInterval else {
                DispatchQueue.main.async { completion(.failure(AuthError.invalidResponse)) }
                return
            }

            SecurityService.shared.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
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
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? TimeInterval else {
                DispatchQueue.main.async { completion(.failure(AuthError.invalidResponse)) }
                return
            }

            SecurityService.shared.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
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

enum AuthError: Error {
    case invalidURL
    case noAuthCode
    case invalidResponse
}
