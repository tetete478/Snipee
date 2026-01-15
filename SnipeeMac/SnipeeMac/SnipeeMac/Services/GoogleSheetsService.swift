//
//  GoogleSheetsService.swift
//  SnipeeMac
//

import Foundation

class GoogleSheetsService {
    static let shared = GoogleSheetsService()
    
    private let spreadsheetId = "1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM"
    private let memberSheetName = "メンバーリスト"
    private let departmentSheetName = "部署設定"
    
    private init() {}
    
    // MARK: - Fetch Member Info
    
    func fetchMemberInfo(email: String, completion: @escaping (Result<MemberInfo, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.fetchMemberSheet(token: token, email: email, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchMemberSheet(token: String, email: String, completion: @escaping (Result<MemberInfo, Error>) -> Void) {
        let range = "\(memberSheetName)!A:D"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(SheetsError.noData)) }
                return
            }
            
            do {
                let sheetData = try JSONDecoder().decode(SheetResponse.self, from: data)
                
                // Find member by email
                guard let values = sheetData.values else {
                    DispatchQueue.main.async { completion(.failure(SheetsError.memberNotFound)) }
                    return
                }
                
                for row in values.dropFirst() { // Skip header
                    if row.count >= 4 && row[1].lowercased() == email.lowercased() {
                        let member = MemberInfo(
                            name: row[0],
                            email: row[1],
                            department: row[2],
                            role: row[3]
                        )
                        DispatchQueue.main.async { completion(.success(member)) }
                        return
                    }
                }
                
                DispatchQueue.main.async { completion(.failure(SheetsError.memberNotFound)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Fetch Department XML File ID
    
    func fetchDepartmentFileId(department: String, completion: @escaping (Result<String, Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.fetchDepartmentSheet(token: token, department: department, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchDepartmentSheet(token: String, department: String, completion: @escaping (Result<String, Error>) -> Void) {
        let range = "\(departmentSheetName)!A:B"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(SheetsError.noData)) }
                return
            }
            
            do {
                let sheetData = try JSONDecoder().decode(SheetResponse.self, from: data)
                
                guard let values = sheetData.values else {
                    DispatchQueue.main.async { completion(.failure(SheetsError.departmentNotFound)) }
                    return
                }
                
                for row in values.dropFirst() { // Skip header
                    if row.count >= 2 && row[0] == department {
                        let fileId = row[1]
                        DispatchQueue.main.async { completion(.success(fileId)) }
                        return
                    }
                }
                
                DispatchQueue.main.async { completion(.failure(SheetsError.departmentNotFound)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}

// MARK: - Models

struct MemberInfo {
    let name: String
    let email: String
    let department: String
    let role: String
}

struct SheetResponse: Codable {
    let values: [[String]]?
}

// MARK: - Errors

enum SheetsError: Error, LocalizedError {
    case invalidURL
    case noData
    case memberNotFound
    case departmentNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .noData: return "データがありません"
        case .memberNotFound: return "メンバーが見つかりません"
        case .departmentNotFound: return "部署が見つかりません"
        }
    }
}
