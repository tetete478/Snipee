//
//  StorageService.swift
//  SnipeeIOS
//

import Foundation

class StorageService {
    static let shared = StorageService()

    private let appGroupId = "group.com.addness.snipee"
    private let snippetsKey = "snippets"
    private let settingsKey = "settings"
    private let lastSyncKey = "lastSyncDate"

    private var userDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: appGroupId)
        if defaults == nil {
            print("❌ [Storage] App Group UserDefaults 取得失敗: \(appGroupId)")
        }
        return defaults
    }

    private init() {
        print("📱 [Storage] init() - App Group: \(appGroupId)")
    }

    // MARK: - Snippets

    func saveSnippets(_ folders: [SnippetFolder]) {
        print("📱 [Storage] saveSnippets() 開始: \(folders.count) フォルダ")

        guard let data = try? JSONEncoder().encode(folders) else {
            print("❌ [Storage] フォルダのエンコード失敗")
            return
        }

        print("📱 [Storage] エンコード成功: \(data.count) bytes")

        guard let defaults = userDefaults else {
            print("❌ [Storage] UserDefaults なし")
            return
        }

        defaults.set(data, forKey: snippetsKey)
        defaults.set(Date(), forKey: lastSyncKey)
        defaults.synchronize()

        print("✅ [Storage] saveSnippets() 完了")

        if let savedData = defaults.data(forKey: snippetsKey) {
            print("📱 [Storage] 保存確認: \(savedData.count) bytes")
        } else {
            print("❌ [Storage] 保存確認失敗")
        }
    }

    func getSnippets() -> [SnippetFolder] {
        print("📱 [Storage] getSnippets() 開始")

        guard let defaults = userDefaults else {
            print("❌ [Storage] UserDefaults なし")
            return []
        }

        guard let data = defaults.data(forKey: snippetsKey) else {
            print("⚠️ [Storage] データなし（初回起動または未同期）")
            return []
        }

        print("📱 [Storage] データ取得: \(data.count) bytes")

        guard let folders = try? JSONDecoder().decode([SnippetFolder].self, from: data) else {
            print("❌ [Storage] デコード失敗")
            return []
        }

        print("✅ [Storage] getSnippets() 完了: \(folders.count) フォルダ")
        return folders
    }

    func getMasterSnippets() -> [SnippetFolder] {
        return getSnippets().map { folder in
            var filtered = folder
            filtered.snippets = folder.snippets.filter { $0.type == .master }
            return filtered
        }.filter { !$0.snippets.isEmpty }
    }

    func getPersonalSnippets() -> [SnippetFolder] {
        return getSnippets().map { folder in
            var filtered = folder
            filtered.snippets = folder.snippets.filter { $0.type == .personal }
            return filtered
        }.filter { !$0.snippets.isEmpty }
    }

    func searchSnippets(query: String) -> [Snippet] {
        let lowercased = query.lowercased()
        return getSnippets()
            .flatMap { $0.snippets }
            .filter {
                $0.title.lowercased().contains(lowercased) ||
                $0.content.lowercased().contains(lowercased)
            }
    }

    // MARK: - Personal Snippets (Cloud Sync用)

    func savePersonalSnippets(_ folders: [SnippetFolder]) {
        print("📱 [Storage] savePersonalSnippets() 開始: \(folders.count) フォルダ")

        let allFolders = getSnippets()

        let masterFolders = allFolders.filter { folder in
            folder.snippets.contains { $0.type == .master }
        }.map { folder -> SnippetFolder in
            var f = folder
            f.snippets = folder.snippets.filter { $0.type == .master }
            return f
        }

        var mergedFolders: [SnippetFolder] = masterFolders

        for personalFolder in folders {
            if let existingIndex = mergedFolders.firstIndex(where: { $0.id == personalFolder.id }) {
                mergedFolders[existingIndex].snippets.append(contentsOf: personalFolder.snippets)
            } else {
                mergedFolders.append(personalFolder)
            }
        }

        saveSnippets(mergedFolders)
        print("✅ [Storage] savePersonalSnippets() 完了")
    }

    // MARK: - Settings

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            print("❌ [Storage] 設定のエンコード失敗")
            return
        }
        userDefaults?.set(data, forKey: settingsKey)
        userDefaults?.synchronize()
        print("✅ [Storage] 設定保存完了")
    }

    func getSettings() -> AppSettings {
        guard let data = userDefaults?.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            print("⚠️ [Storage] 設定なし（デフォルト使用）")
            return .default
        }
        return settings
    }

    // MARK: - Data Expiry

    func isDataExpired() -> Bool {
        guard let lastSync = userDefaults?.object(forKey: lastSyncKey) as? Date else {
            return true
        }
        let settings = getSettings()
        let expiryDate = lastSync.addingTimeInterval(TimeInterval(settings.dataExpiryDays * 24 * 60 * 60))
        return Date() > expiryDate
    }
    
    /// クラウドから取得したデータを保存（同期トリガーなし）
    func savePersonalSnippetsFromCloud(_ folders: [SnippetFolder]) {
        print("📱 [Storage] savePersonalSnippetsFromCloud() 開始: \(folders.count) フォルダ")
        
        let allFolders = getSnippets()
        
        // マスターのみ抽出
        let masterFolders = allFolders.filter { folder in
            folder.snippets.contains { $0.type == .master }
        }.map { folder -> SnippetFolder in
            var f = folder
            f.snippets = folder.snippets.filter { $0.type == .master }
            return f
        }
        
        // マスター + 新しい個別スニペットをマージ
        var mergedFolders: [SnippetFolder] = masterFolders
        
        for personalFolder in folders {
            if let existingIndex = mergedFolders.firstIndex(where: { $0.id == personalFolder.id }) {
                mergedFolders[existingIndex].snippets.append(contentsOf: personalFolder.snippets)
            } else {
                mergedFolders.append(personalFolder)
            }
        }
        
        // 直接保存（saveSnippetsを使う）
        saveSnippets(mergedFolders)
        print("✅ [Storage] savePersonalSnippetsFromCloud() 完了")
    }

    func clearAllData() {
        print("📱 [Storage] clearAllData() 実行")
        userDefaults?.removeObject(forKey: snippetsKey)
        userDefaults?.removeObject(forKey: settingsKey)
        userDefaults?.removeObject(forKey: lastSyncKey)
        userDefaults?.synchronize()
        print("✅ [Storage] 全データ削除完了")
    }
}
