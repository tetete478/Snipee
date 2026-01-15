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
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media"
        
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
        let urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DriveError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { _, response, error in
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

// MARK: - Errors

enum DriveError: Error, LocalizedError {
    case invalidURL
    case noData
    case fileNotFound
    case downloadFailed
    case uploadFailed
    case noPermission
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .noData: return "データがありません"
        case .fileNotFound: return "ファイルが見つかりません"
        case .downloadFailed: return "ダウンロードに失敗しました"
        case .uploadFailed: return "アップロードに失敗しました"
        case .noPermission: return "編集権限がありません"
        }
    }
}
