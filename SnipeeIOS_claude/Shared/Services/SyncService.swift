//
//  SyncService.swift
//  SnipeeIOS
//

import Foundation

class SyncService {
    static let shared = SyncService()

    private let spreadsheetIdKey = "spreadsheetId"

    private var spreadsheetId: String? {
        get { UserDefaults.standard.string(forKey: spreadsheetIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: spreadsheetIdKey) }
    }

    private init() {}

    func sync(completion: @escaping (Result<Void, Error>) -> Void) {
        // First, refresh token if needed
        GoogleAuthService.shared.refreshTokenIfNeeded { [weak self] result in
            switch result {
            case .success:
                self?.performSync(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performSync(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let spreadsheetId = spreadsheetId else {
            completion(.failure(SyncError.noSpreadsheet))
            return
        }

        // Read master snippets
        GoogleSheetsService.shared.readSheet(
            spreadsheetId: spreadsheetId,
            range: "Master!A2:E"
        ) { [weak self] result in
            switch result {
            case .success(let rows):
                let masterSnippets = self?.parseSnippets(rows: rows, type: .master) ?? []
                self?.fetchPersonalSnippets(spreadsheetId: spreadsheetId, masterSnippets: masterSnippets, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchPersonalSnippets(spreadsheetId: String, masterSnippets: [Snippet], completion: @escaping (Result<Void, Error>) -> Void) {
        GoogleSheetsService.shared.readSheet(
            spreadsheetId: spreadsheetId,
            range: "Personal!A2:E"
        ) { [weak self] result in
            switch result {
            case .success(let rows):
                let personalSnippets = self?.parseSnippets(rows: rows, type: .personal) ?? []
                self?.mergeAndSave(masterSnippets: masterSnippets, personalSnippets: personalSnippets)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func parseSnippets(rows: [[String]], type: SnippetType) -> [Snippet] {
        var snippets: [Snippet] = []

        for (index, row) in rows.enumerated() {
            guard row.count >= 3 else { continue }

            let snippet = Snippet(
                id: row.count > 3 ? row[3] : UUID().uuidString,
                title: row[0],
                content: row[1],
                folder: row[2],
                type: type,
                order: index
            )
            snippets.append(snippet)
        }

        return snippets
    }

    private func mergeAndSave(masterSnippets: [Snippet], personalSnippets: [Snippet]) {
        let allSnippets = masterSnippets + personalSnippets

        // Group by folder
        var folderDict: [String: [Snippet]] = [:]
        for snippet in allSnippets {
            folderDict[snippet.folder, default: []].append(snippet)
        }

        // Create folders
        let folders = folderDict.enumerated().map { index, element in
            SnippetFolder(
                name: element.key,
                snippets: element.value.sorted { $0.order < $1.order },
                order: index
            )
        }.sorted { $0.name < $1.name }

        StorageService.shared.saveSnippets(folders)
    }

    func setSpreadsheetId(_ id: String) {
        spreadsheetId = id
    }

    func getSpreadsheetId() -> String? {
        return spreadsheetId
    }
}

enum SyncError: Error {
    case noSpreadsheet
    case parseError
}
