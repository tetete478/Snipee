//
//  GoogleDriveService.swift
//  SnipeeMac
//

import Foundation

class GoogleDriveService {
    static let shared = GoogleDriveService()
    
    private init() {}
    
    // MARK: - Download XML File
    
    func downloadXMLFile(fileId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.downloadFile(fileId: fileId, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func downloadFile(fileId: String, token: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media&supportsAllDrives=true"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    DispatchQueue.main.async { completion(.failure(DriveError.fileNotFound)) }
                    return
                }
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.downloadFailed)) }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }
            
            DispatchQueue.main.async { completion(.success(data)) }
        }.resume()
    }
    
    // MARK: - Upload XML File
    
    func uploadXMLFile(fileId: String, xmlData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.uploadFile(fileId: fileId, data: xmlData, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func uploadFile(fileId: String, data: Data, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media&supportsAllDrives=true"

        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
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
    
    // MARK: - Download JSON File
    
    func downloadJSONFile(fileId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.downloadFile(fileId: fileId, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Upload JSON File (Update existing)
    
    func uploadJSONFile(fileId: String, jsonData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.updateJSONFile(fileId: fileId, data: jsonData, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateJSONFile(fileId: String, data: Data, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media&supportsAllDrives=true"

        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
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
    
    // MARK: - Find File
    
    func findFile(name: String, parentId: String?, completion: @escaping (Result<DriveFile?, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.searchFile(name: name, parentId: parentId, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func searchFile(name: String, parentId: String?, token: String, completion: @escaping (Result<DriveFile?, Error>) -> Void) {
        var query = "name='\(name)' and trashed=false"
        if let parentId = parentId {
            query += " and '\(parentId)' in parents"
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)&spaces=drive&fields=files(id,name,mimeType,modifiedTime)&supportsAllDrives=true"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.searchFailed)) }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }
            
            do {
                let searchResult = try JSONDecoder().decode(DriveSearchResponse.self, from: data)
                let file = searchResult.files.first
                DispatchQueue.main.async { completion(.success(file)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Create File
    
    func createFile(name: String, content: Data, parentId: String?, mimeType: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.createNewFile(name: name, content: content, parentId: parentId, mimeType: mimeType, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createNewFile(name: String, content: Data, parentId: String?, mimeType: String, token: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let urlString = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true&fields=id,name,mimeType,modifiedTime"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var metadata: [String: Any] = [
            "name": name,
            "mimeType": mimeType
        ]
        if let parentId = parentId {
            metadata["parents"] = [parentId]
        }
        
        guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata) else {
            completion(.failure(DriveError.createFailed))
            return
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(content)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
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
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.createFailed)) }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }
            
            do {
                let file = try JSONDecoder().decode(DriveFile.self, from: data)
                DispatchQueue.main.async { completion(.success(file)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Create Folder
    
    func createFolder(name: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.createNewFolder(name: name, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createNewFolder(name: String, token: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/drive/v3/files?supportsAllDrives=true&fields=id,name,mimeType,modifiedTime"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        
        guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata) else {
            completion(.failure(DriveError.createFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = metadataData
        
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
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.createFailed)) }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }
            
            do {
                let file = try JSONDecoder().decode(DriveFile.self, from: data)
                DispatchQueue.main.async { completion(.success(file)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Get File Metadata
    
    func getFileMetadata(fileId: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.fetchFileMetadata(fileId: fileId, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchFileMetadata(fileId: String, token: String, completion: @escaping (Result<DriveFile, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)?fields=id,name,mimeType,modifiedTime&supportsAllDrives=true"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    DispatchQueue.main.async { completion(.failure(DriveError.fileNotFound)) }
                    return
                }
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async { completion(.failure(DriveError.downloadFailed)) }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(DriveError.noData)) }
                return
            }
            
            do {
                let file = try JSONDecoder().decode(DriveFile.self, from: data)
                DispatchQueue.main.async { completion(.success(file)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}

// MARK: - Drive Models

struct DriveFile: Codable {
    let id: String
    let name: String
    let mimeType: String
    let modifiedTime: String?
}

struct DriveSearchResponse: Codable {
    let files: [DriveFile]
}

// MARK: - Errors

enum DriveError: Error, LocalizedError {
    case invalidURL
    case noData
    case fileNotFound
    case downloadFailed
    case uploadFailed
    case noPermission
    case createFailed
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .noData: return "データがありません"
        case .fileNotFound: return "ファイルが見つかりません"
        case .downloadFailed: return "ダウンロードに失敗しました"
        case .uploadFailed: return "アップロードに失敗しました"
        case .noPermission: return "編集権限がありません"
        case .createFailed: return "ファイル作成に失敗しました"
        case .searchFailed: return "検索に失敗しました"
        }
    }
}
