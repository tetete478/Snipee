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
        UserDefaults(suiteName: appGroupId)
    }

    private init() {}

    // MARK: - Snippets

    func saveSnippets(_ folders: [SnippetFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        userDefaults?.set(data, forKey: snippetsKey)
        userDefaults?.set(Date(), forKey: lastSyncKey)
    }

    func getSnippets() -> [SnippetFolder] {
        guard let data = userDefaults?.data(forKey: snippetsKey),
              let folders = try? JSONDecoder().decode([SnippetFolder].self, from: data) else {
            return []
        }
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

    // MARK: - Settings

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults?.set(data, forKey: settingsKey)
    }

    func getSettings() -> AppSettings {
        guard let data = userDefaults?.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
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

    func clearAllData() {
        userDefaults?.removeObject(forKey: snippetsKey)
        userDefaults?.removeObject(forKey: settingsKey)
        userDefaults?.removeObject(forKey: lastSyncKey)
    }
}
