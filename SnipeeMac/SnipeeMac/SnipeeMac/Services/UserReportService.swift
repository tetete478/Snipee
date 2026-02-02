//
//  UserReportService.swift
//  SnipeeMac
//

import Foundation

class UserReportService {
    static let shared = UserReportService()
    
    private let spreadsheetId = "1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM"
    private let sheetName = "メンバーリスト"
    
    private init() {}
    
    // MARK: - Report User Status
    
    func reportUserStatus() {
        guard let email = GoogleAuthService.shared.userEmail else { return }
        
        GoogleAuthService.shared.getAccessToken { [weak self] result in
            switch result {
            case .success(let token):
                self?.findUserRowAndUpdate(token: token, email: email)
            case .failure:
                break
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func findUserRowAndUpdate(token: String, email: String) {
        // まずメールアドレス列(B列)を取得して行番号を特定
        let range = "\(sheetName)!B:B"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range)"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let sheetData = try? JSONDecoder().decode(SheetResponse.self, from: data),
                  let values = sheetData.values else {
                return
            }

            // メールアドレスで行番号を検索（1-indexed、ヘッダー含む）
            for (index, row) in values.enumerated() {
                if let cellEmail = row.first, cellEmail.lowercased() == email.lowercased() {
                    let rowNumber = index + 1 // スプシは1-indexed
                    self?.updateUserRow(token: token, rowNumber: rowNumber)
                    return
                }
            }
        }.resume()
    }
    
    private func updateUserRow(token: String, rowNumber: Int) {
        // E列: バージョン, F列: 最終起動, G列: 個別スニペット数
        let range = "\(sheetName)!E\(rowNumber):G\(rowNumber)"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range)?valueInputOption=USER_ENTERED"
        
        guard let url = URL(string: urlString) else { return }
        
        // データ準備
        let version = Constants.App.version
        let lastActive = formatCurrentDateTime()
        let snippetCount = countPersonalSnippets()
        
        let body: [String: Any] = [
            "values": [[version, lastActive, snippetCount]]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Silent update
        }.resume()
    }
    
    // MARK: - Helpers
    
    private func formatCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }
    
    private func countPersonalSnippets() -> Int {
        let folders = StorageService.shared.getPersonalSnippets()
        return folders.reduce(0) { $0 + $1.snippets.count }
    }
}
