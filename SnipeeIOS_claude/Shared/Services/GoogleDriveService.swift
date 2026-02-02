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

enum DriveError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
}
