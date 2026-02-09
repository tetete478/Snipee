//
//  GoogleSheetsService.swift
//  SnipeeIOS
//

import Foundation

class GoogleSheetsService {
    static let shared = GoogleSheetsService()

    private let baseUrl = "https://sheets.googleapis.com/v4/spreadsheets"

    // Mac版と同じ設定値
    let defaultSpreadsheetId = "1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM"
    let memberSheetName = "メンバーリスト"
    let departmentSheetName = "部署設定"

    private init() {}

    func readSheet(spreadsheetId: String, range: String, completion: @escaping (Result<[[String]], Error>) -> Void) {
        print("📱 [Sheets] readSheet() 開始: \(range)")

        guard let accessToken = SecurityService.shared.getAccessToken() else {
            print("❌ [Sheets] アクセストークンなし")
            completion(.failure(SheetsError.notAuthenticated))
            return
        }

        print("📱 [Sheets] アクセストークン: \(accessToken.prefix(20))...")

        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseUrl)/\(spreadsheetId)/values/\(encodedRange)"

        print("📱 [Sheets] URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [Sheets] URL生成失敗")
            completion(.failure(SheetsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [Sheets] ネットワークエラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            // HTTPレスポンスコード確認
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 [Sheets] HTTPステータス: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [Sheets] エラーレスポンス: \(errorString.prefix(500))")
                    }
                }
            }

            guard let data = data else {
                print("❌ [Sheets] データなし")
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            // レスポンス内容をデバッグ出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 [Sheets] レスポンス: \(responseString.prefix(300))...")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [Sheets] JSON解析失敗")
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            guard let values = json["values"] as? [[String]] else {
                print("⚠️ [Sheets] 'values' キーなし（データが空の可能性）")
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            print("✅ [Sheets] 読み込み成功: \(values.count) 行")
            DispatchQueue.main.async { completion(.success(values)) }
        }.resume()
    }

    func writeSheet(spreadsheetId: String, range: String, values: [[String]], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(SheetsError.notAuthenticated))
            return
        }

        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseUrl)/\(spreadsheetId)/values/\(encodedRange)?valueInputOption=RAW"

        guard let url = URL(string: urlString) else {
            completion(.failure(SheetsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "range": range,
            "majorDimension": "ROWS",
            "values": values
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    func appendSheet(spreadsheetId: String, range: String, values: [[String]], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(SheetsError.notAuthenticated))
            return
        }

        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseUrl)/\(spreadsheetId)/values/\(encodedRange):append?valueInputOption=RAW&insertDataOption=INSERT_ROWS"

        guard let url = URL(string: urlString) else {
            completion(.failure(SheetsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "range": range,
            "majorDimension": "ROWS",
            "values": values
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    func createSpreadsheet(title: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(SheetsError.notAuthenticated))
            return
        }

        let url = URL(string: baseUrl)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "properties": [
                "title": title
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let spreadsheetId = json["spreadsheetId"] as? String else {
                DispatchQueue.main.async { completion(.failure(SheetsError.invalidResponse)) }
                return
            }

            DispatchQueue.main.async { completion(.success(spreadsheetId)) }
        }.resume()
    }
}

enum SheetsError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case memberNotFound
    case departmentNotFound
    case noData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "認証されていません"
        case .invalidURL: return "無効なURLです"
        case .invalidResponse: return "無効なレスポンスです"
        case .memberNotFound: return "メンバーが見つかりません"
        case .departmentNotFound: return "部署が見つかりません"
        case .noData: return "データがありません"
        }
    }
}

// MARK: - Models

struct SheetMemberInfo {
    let name: String
    let email: String
    let department: String
    let role: String
}

struct DepartmentInfo: Hashable {
    let name: String
    let fileId: String
}

// MARK: - Member/Department Methods

extension GoogleSheetsService {
    func fetchMemberInfo(email: String, completion: @escaping (Result<SheetMemberInfo, Error>) -> Void) {
        readSheet(spreadsheetId: defaultSpreadsheetId, range: "\(memberSheetName)!A:D") { result in
            switch result {
            case .success(let values):
                for row in values.dropFirst() {
                    if row.count >= 4 && row[1].lowercased() == email.lowercased() {
                        let member = SheetMemberInfo(
                            name: row[0],
                            email: row[1],
                            department: row[2],
                            role: row[3]
                        )
                        completion(.success(member))
                        return
                    }
                }
                completion(.failure(SheetsError.memberNotFound))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchDepartmentFileId(department: String, completion: @escaping (Result<String, Error>) -> Void) {
        readSheet(spreadsheetId: defaultSpreadsheetId, range: "\(departmentSheetName)!A:B") { result in
            switch result {
            case .success(let values):
                for row in values.dropFirst() {
                    if row.count >= 2 && row[0] == department {
                        completion(.success(row[1]))
                        return
                    }
                }
                completion(.failure(SheetsError.departmentNotFound))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchAllDepartments(completion: @escaping (Result<[DepartmentInfo], Error>) -> Void) {
        readSheet(spreadsheetId: defaultSpreadsheetId, range: "\(departmentSheetName)!A:B") { result in
            switch result {
            case .success(let values):
                var departments: [DepartmentInfo] = []
                for row in values.dropFirst() {
                    if row.count >= 2 {
                        departments.append(DepartmentInfo(name: row[0], fileId: row[1]))
                    }
                }
                completion(.success(departments))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
