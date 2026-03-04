
//
//  StorageService.swift
//  SnipeeMac
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let history = "clipboard_history"
        static let personalSnippets = "personal_snippets"
        static let personalSnippetsBackup = "personal_snippets_backup"
        static let masterSnippets = "master_snippets"
        static let settings = "app_settings"
        static let hasCompletedOnboarding = "has_completed_onboarding"
    }
    
    private init() {}
    
    // MARK: - History
    
    func getHistory() -> [HistoryItem] {
        guard let data = userDefaults.data(forKey: Keys.history),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return items
    }
    
    func saveHistory(_ items: [HistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: Keys.history)
    }
    
    func addHistoryItem(_ item: HistoryItem) {
        var items = getHistory()
        // Remove duplicate
        items.removeAll { $0.content == item.content }
        // Add to beginning
        items.insert(item, at: 0)
        // Limit count
        let settings = getSettings()
        if items.count > settings.historyMaxCount {
            items = Array(items.prefix(settings.historyMaxCount))
        }
        saveHistory(items)
    }
    
    func clearHistory() {
        let items = getHistory().filter { $0.isPinned }
        saveHistory(items)
    }
    
    // MARK: - Snippets
    
    func getPersonalSnippets() -> [SnippetFolder] {
        guard let data = userDefaults.data(forKey: Keys.personalSnippets),
              let folders = try? JSONDecoder().decode([SnippetFolder].self, from: data) else {
            return []
        }
        return folders
    }

    func savePersonalSnippets(_ folders: [SnippetFolder]) {
        if let currentData = userDefaults.data(forKey: Keys.personalSnippets) {
            userDefaults.set(currentData, forKey: Keys.personalSnippetsBackup)
        }
        guard let data = try? JSONEncoder().encode(folders) else {
            return
        }
        userDefaults.set(data, forKey: Keys.personalSnippets)
    }
    
    func getMasterSnippets() -> [SnippetFolder] {
        guard let data = userDefaults.data(forKey: Keys.masterSnippets),
              let folders = try? JSONDecoder().decode([SnippetFolder].self, from: data) else {
            return []
        }
        return folders
    }
    
    func saveMasterSnippets(_ folders: [SnippetFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        userDefaults.set(data, forKey: Keys.masterSnippets)
    }
    
    // MARK: - Settings
    
    func getSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.settings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: Keys.settings)
    }
    
    // MARK: - Onboarding
    
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
}
