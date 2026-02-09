//
//  SyncService.swift
//  SnipeeIOS
//

import Foundation

struct MemberInfo {
    var name: String?
    var email: String?
    var department: String?
    var role: String?
}

class SyncService {
    static let shared = SyncService()

    private let memberInfoKey = "cachedMemberInfo"
    private var lastSyncedFileId: String?

    private init() {}

    // MARK: - Member Info

    func getCachedMemberInfo() -> MemberInfo {
        let name = UserDefaults.standard.string(forKey: "userName")
        let email = UserDefaults.standard.string(forKey: "userEmail")
        let department = UserDefaults.standard.string(forKey: "userDepartment")
        let role = UserDefaults.standard.string(forKey: "userRole")

        return MemberInfo(name: name, email: email, department: department, role: role)
    }

    func saveMemberInfo(_ member: SheetMemberInfo) {
        UserDefaults.standard.set(member.name, forKey: "userName")
        UserDefaults.standard.set(member.email, forKey: "userEmail")
        UserDefaults.standard.set(member.department, forKey: "userDepartment")
        UserDefaults.standard.set(member.role, forKey: "userRole")

        // 設定にもユーザー名を保存
        var settings = StorageService.shared.getSettings()
        settings.userName = member.name
        StorageService.shared.saveSettings(settings)

        print("✅ [Sync] メンバー情報保存: \(member.name), \(member.department), \(member.role)")
    }

    // MARK: - Async/Await API

    func syncMasterSnippets() async {
        print("🔴🔴🔴 [Sync] syncMasterSnippets() 開始 🔴🔴🔴")

        // ログインチェック
        let email = GoogleAuthService.shared.currentUserEmail
        print("🔴 [Sync] currentUserEmail = \(email ?? "nil")")
        print("🔴 [Sync] isSignedIn = \(GoogleAuthService.shared.isSignedIn())")

        await withCheckedContinuation { continuation in
            syncMasterSnippets { result in
                switch result {
                case .success(let syncResult):
                    print("✅✅✅ [Sync] 同期完了: \(syncResult.folderCount) フォルダ, \(syncResult.snippetCount) スニペット")
                case .failure(let error):
                    print("❌❌❌ [Sync] 同期失敗: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    func fetchAndSaveMemberInfo() async {
        print("📱 [Sync] fetchAndSaveMemberInfo() 開始")

        guard let email = GoogleAuthService.shared.currentUserEmail else {
            print("❌ [Sync] ユーザーメールなし")
            return
        }

        print("📱 [Sync] メール: \(email)")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GoogleSheetsService.shared.fetchMemberInfo(email: email) { [weak self] result in
                switch result {
                case .success(let member):
                    self?.saveMemberInfo(member)
                case .failure(let error):
                    print("❌ [Sync] メンバー情報取得失敗: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Callback-based API (Mac版と同じフロー)

    func syncMasterSnippets(completion: @escaping (Result<SyncResult, Error>) -> Void) {
        print("📱 [Sync] syncMasterSnippets(callback) 開始")

        // 1. Get logged in user email
        guard let email = GoogleAuthService.shared.currentUserEmail else {
            print("❌ [Sync] ユーザーメールなし")
            completion(.failure(SyncError.notLoggedIn))
            return
        }

        print("📱 [Sync] ユーザーメール: \(email)")

        // 2. Fetch member info from Sheets
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { [weak self] result in
            switch result {
            case .success(let member):
                print("✅ [Sync] メンバー情報取得: \(member.name), 部署=\(member.department)")
                self?.saveMemberInfo(member)

                // 3. Fetch department XML file ID
                self?.fetchAndDownloadXML(department: member.department, member: member, completion: completion)

            case .failure(let error):
                print("❌ [Sync] メンバー情報取得失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private func fetchAndDownloadXML(department: String, member: SheetMemberInfo, completion: @escaping (Result<SyncResult, Error>) -> Void) {
        print("📱 [Sync] 部署XMLファイルID取得中: \(department)")

        GoogleSheetsService.shared.fetchDepartmentFileId(department: department) { [weak self] result in
            switch result {
            case .success(let fileId):
                print("✅ [Sync] XMLファイルID取得: \(fileId)")
                self?.lastSyncedFileId = fileId

                // modifiedTime チェック（バックグラウンドで実行）
                Task {
                    await self?.checkModifiedTimeAndSync(fileId: fileId, member: member, completion: completion)
                }

            case .failure(let error):
                print("❌ [Sync] 部署XMLファイルID取得失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private func checkModifiedTimeAndSync(fileId: String, member: SheetMemberInfo, completion: @escaping (Result<SyncResult, Error>) -> Void) async {
        // modifiedTime を取得
        let currentModifiedTime = await GoogleDriveService.shared.getFileModifiedTime(fileId: fileId)

        // 前回の modifiedTime と比較
        let settings = StorageService.shared.getSettings()
        if let lastModifiedTime = settings.lastModifiedTime,
           let currentModifiedTime = currentModifiedTime,
           lastModifiedTime == currentModifiedTime {
            print("✅ [Sync] 変更なし（modifiedTime一致）- 同期スキップ")
            let syncResult = SyncResult(
                folderCount: 0,
                snippetCount: 0,
                syncDate: Date(),
                memberName: member.name,
                memberDepartment: member.department,
                memberRole: member.role,
                skipped: true
            )
            DispatchQueue.main.async {
                completion(.success(syncResult))
            }
            return
        }

        print("📱 [Sync] 変更あり - フル同期実行")

        // フル同期実行
        downloadAndParseXML(fileId: fileId, member: member, modifiedTime: currentModifiedTime, completion: completion)
    }

    private func downloadAndParseXML(fileId: String, member: SheetMemberInfo, modifiedTime: String? = nil, completion: @escaping (Result<SyncResult, Error>) -> Void) {
        print("📱 [Sync] XMLダウンロード中: \(fileId)")

        GoogleDriveService.shared.downloadXMLFile(fileId: fileId) { result in
            switch result {
            case .success(let data):
                print("✅ [Sync] XMLダウンロード成功: \(data.count) bytes")

                // デバッグ: XML内容の一部を出力
                if let xmlString = String(data: data, encoding: .utf8) {
                    print("📱 [Sync] XML内容: \(xmlString.prefix(500))...")
                }

                // 5. Parse XML
                let parser = XMLParserHelper()
                let folders = parser.parse(data: data)

                print("📱 [Sync] XMLパース結果: \(folders.count) フォルダ")
                for folder in folders {
                    print("  📁 \(folder.name): \(folder.snippets.count) スニペット")
                }

                // 6. Save as master snippets
                StorageService.shared.saveSnippets(folders)

                // Update last sync date and modifiedTime
                var settings = StorageService.shared.getSettings()
                settings.lastSyncDate = Date()
                if let modifiedTime = modifiedTime {
                    settings.lastModifiedTime = modifiedTime
                    print("📱 [Sync] lastModifiedTime 保存: \(modifiedTime)")
                }
                StorageService.shared.saveSettings(settings)

                let syncResult = SyncResult(
                    folderCount: folders.count,
                    snippetCount: folders.reduce(0) { $0 + $1.snippets.count },
                    syncDate: Date(),
                    memberName: member.name,
                    memberDepartment: member.department,
                    memberRole: member.role,
                    skipped: false
                )

                DispatchQueue.main.async {
                    completion(.success(syncResult))
                }

            case .failure(let error):
                print("❌ [Sync] XMLダウンロード失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Models

struct SyncResult {
    let folderCount: Int
    let snippetCount: Int
    let syncDate: Date
    let memberName: String?
    let memberDepartment: String?
    let memberRole: String?
    let skipped: Bool
}

// MARK: - Errors

enum SyncError: Error, LocalizedError {
    case notLoggedIn
    case syncFailed
    case noSpreadsheet
    case parseError

    var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "ログインしてください"
        case .syncFailed: return "同期に失敗しました"
        case .noSpreadsheet: return "スプレッドシートが設定されていません"
        case .parseError: return "データの解析に失敗しました"
        }
    }
}
