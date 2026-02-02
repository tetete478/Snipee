//
//  GoogleSheetsService.swift
//  SnipeeIOS
//

import Foundation

class GoogleSheetsService {
    static let shared = GoogleSheetsService()

    private let baseUrl = "https://sheets.googleapis.com/v4/spreadsheets"

    private init() {}

    func readSheet(spreadsheetId: String, range: String, completion: @escaping (Result<[[String]], Error>) -> Void) {
        guard let accessToken = SecurityService.shared.getAccessToken() else {
            completion(.failure(SheetsError.notAuthenticated))
            return
        }

        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseUrl)/\(spreadsheetId)/values/\(encodedRange)"

        guard let url = URL(string: urlString) else {
            completion(.failure(SheetsError.invalidURL))
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
                  let values = json["values"] as? [[String]] else {
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

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

enum SheetsError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
}
