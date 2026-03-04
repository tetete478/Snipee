//
//  GoogleDriveService.swift
//  SnipeeIOS
//

import Foundation

class GoogleDriveService {
    static let shared = GoogleDriveService()

    private let baseUrl = "https://www.googleapis.com/drive/v3"

    private init() {}

    func findOrCreateFolder(name: String, completion: @escaping (Result<String, Error>) -> Void) {
        // First, search for existing folder
        searchFolder(name: name) { [weak self] result in
            switch result {
            case .success(let folderId):
                if let folderId = folderId {
                    completion(.success(folderId))
                } else {
                    self?.createFolder(name: name, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func searchFolder(name: String, completion: @escaping (Result<String?, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        let query = "name='\(name)' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseUrl)/files?q=\(encodedQuery)&fields=files(id,name)"

        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let files = json["files"] as? [[String: Any]] else {
                DispatchQueue.main.async { completion(.success(nil)) }
                return
            }

            let folderId = files.first?["id"] as? String
            DispatchQueue.main.async { completion(.success(folderId)) }
        }.resume()
    }

    private func createFolder(name: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        let url = URL(string: "\(baseUrl)/files")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: metadata)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let folderId = json["id"] as? String else {
                DispatchQueue.main.async { completion(.failure(DriveError.invalidResponse)) }
                return
            }

            DispatchQueue.main.async { completion(.success(folderId)) }
        }.resume()
    }

    func uploadFile(name: String, content: Data, folderId: String, mimeType: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        let boundary = UUID().uuidString
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": name,
            "parents": [folderId]
        ]

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(content)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fileId = json["id"] as? String else {
                DispatchQueue.main.async { completion(.failure(DriveError.invalidResponse)) }
                return
            }

            DispatchQueue.main.async { completion(.success(fileId)) }
        }.resume()
    }

    func downloadFile(fileId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        let url = URL(string: "\(baseUrl)/files/\(fileId)?alt=media")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.invalidResponse)) }
                return
            }

            DispatchQueue.main.async { completion(.success(data)) }
        }.resume()
    }
}

enum DriveError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case fileNotFound
    case downloadFailed
    case uploadFailed
    case noPermission
    case noData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "認証されていません"
        case .invalidURL: return "無効なURLです"
        case .invalidResponse: return "無効なレスポンスです"
        case .fileNotFound: return "ファイルが見つかりません"
        case .downloadFailed: return "ダウンロードに失敗しました"
        case .uploadFailed: return "アップロードに失敗しました"
        case .noPermission: return "編集権限がありません"
        case .noData: return "データがありません"
        }
    }
}

// MARK: - File Metadata

extension GoogleDriveService {
    /// ファイルの modifiedTime を取得（同期スキップ判定用）
    func getFileModifiedTime(fileId: String) async -> String? {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            print("❌ [Drive] getFileModifiedTime: アクセストークンなし")
            return nil
        }

        let urlString = "\(baseUrl)/files/\(fileId)?fields=modifiedTime&supportsAllDrives=true"

        guard let url = URL(string: urlString) else {
            print("❌ [Drive] getFileModifiedTime: URL生成失敗")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    print("❌ [Drive] getFileModifiedTime: HTTPステータス \(httpResponse.statusCode)")
                    return nil
                }
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let modifiedTime = json["modifiedTime"] as? String {
                print("📱 [Drive] modifiedTime: \(modifiedTime)")
                return modifiedTime
            }
        } catch {
            print("❌ [Drive] getFileModifiedTime: \(error.localizedDescription)")
        }

        return nil
    }
}

// MARK: - XML File Methods (Mac版互換)

extension GoogleDriveService {
    /// XMLファイルをダウンロード（マスタースニペット用）
    func downloadXMLFile(fileId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        print("📱 [Drive] downloadXMLFile() 開始: \(fileId)")

        guard let accessToken = SecurityService.shared.getAccessToken() else {
            print("❌ [Drive] アクセストークンなし")
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        // 共有ドライブ対応のため supportsAllDrives=true を追加
        let urlString = "\(baseUrl)/files/\(fileId)?alt=media&supportsAllDrives=true"
        print("📱 [Drive] URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [Drive] URL生成失敗")
            completion(.failure(DriveError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [Drive] ネットワークエラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📱 [Drive] HTTPステータス: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 404 {
                    print("❌ [Drive] ファイルが見つかりません")
                    DispatchQueue.main.async { completion(.failure(DriveError.fileNotFound)) }
                    return
                }
                if httpResponse.statusCode != 200 {
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [Drive] エラーレスポンス: \(errorString.prefix(300))")
                    }
                    DispatchQueue.main.async { completion(.failure(DriveError.downloadFailed)) }
                    return
                }
            }

            guard let data = data else {
                print("❌ [Drive] データなし")
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }

            print("✅ [Drive] ダウンロード成功: \(data.count) bytes")
            DispatchQueue.main.async { completion(.success(data)) }
        }.resume()
    }

    /// XMLファイルをアップロード（マスタースニペット用）
    func uploadXMLFile(fileId: String, xmlData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(DriveError.notAuthenticated))
            return
        }

        let urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media&supportsAllDrives=true"

        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpBody = xmlData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    DispatchQueue.main.async { completion(.failure(DriveError.noPermission)) }
                    return
                }
                if httpResponse.statusCode == 404 {
                    DispatchQueue.main.async { completion(.failure(DriveError.fileNotFound)) }
                    return
                }
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.uploadFailed)) }
                    return
                }
            }

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }
}
