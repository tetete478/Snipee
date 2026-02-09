//
//  GoogleSheetsService.swift
//  SnipeeMac
//

@preconcurrency import Foundation

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
                
                guard let values = sheetData.values else {
                    DispatchQueue.main.async { completion(.failure(SheetsError.memberNotFound)) }
                    return
                }
                
                for row in values.dropFirst() {
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
                    DispatchQueue.main.async { completion(.failure(SheetsError.detailedDepartmentNotFound(searched: department, available: []))) }
                    return
                }
                
                for row in values.dropFirst() {
                    if row.count >= 2 && row[0] == department {
                        let fileId = row[1]
                        DispatchQueue.main.async { completion(.success(fileId)) }
                        return
                    }
                }
                
                let allDepts = values.dropFirst().compactMap { $0.first }
                DispatchQueue.main.async { completion(.failure(SheetsError.detailedDepartmentNotFound(searched: department, available: allDepts))) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Fetch All Members (Super Admin Only)
    
    func fetchAllMembers(completion: @escaping (Result<[UserStatus], Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.fetchAllMembersSheet(token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchAllMembersSheet(token: String, completion: @escaping (Result<[UserStatus], Error>) -> Void) {
        let range = "\(memberSheetName)!A:G"
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
                    DispatchQueue.main.async { completion(.success([])) }
                    return
                }
                
                var users: [UserStatus] = []
                for row in values.dropFirst() {
                    let user = UserStatus(
                        name: row.count > 0 ? row[0] : "",
                        email: row.count > 1 ? row[1] : "",
                        department: row.count > 2 ? row[2] : "",
                        role: row.count > 3 ? row[3] : "",
                        version: row.count > 4 ? row[4] : "",
                        lastActive: row.count > 5 ? row[5] : "",
                        snippetCount: row.count > 6 ? row[6] : ""
                    )
                    users.append(user)
                }
                
                DispatchQueue.main.async { completion(.success(users)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - Fetch All Departments
    
    func fetchAllDepartments(completion: @escaping (Result<[DepartmentInfo], Error>) -> Void) {
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.fetchAllDepartmentsSheet(token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchAllDepartmentsSheet(token: String, completion: @escaping (Result<[DepartmentInfo], Error>) -> Void) {
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
                    DispatchQueue.main.async { completion(.success([])) }
                    return
                }
                
                var departments: [DepartmentInfo] = []
                for row in values.dropFirst() {
                    if row.count >= 2 {
                        departments.append(DepartmentInfo(name: row[0], fileId: row[1]))
                    }
                }
                
                DispatchQueue.main.async { completion(.success(departments)) }
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

struct DepartmentInfo: Hashable {
    let name: String
    let fileId: String
}

struct SheetResponse: Codable, Sendable {
    let values: [[String]]?
}

// MARK: - Errors

enum SheetsError: Error, LocalizedError {
    case invalidURL
    case noData
    case memberNotFound
    case departmentNotFound
    case detailedDepartmentNotFound(searched: String, available: [String])
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .noData: return "データがありません"
        case .memberNotFound: return "メンバーが見つかりません"
        case .departmentNotFound: return "部署が見つかりません"
        case .detailedDepartmentNotFound(let searched, let available):
            return "部署「\(searched)」が見つかりません。\n登録済み部署: \(available.joined(separator: ", "))"
        }
    }
}
