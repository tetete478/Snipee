//
//  SnipeeIOSApp.swift
//  SnipeeIOS
//
//  Created by てててMac on 2026/02/01.
//

import SwiftUI
import Combine

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var folders: [SnippetFolder] = []
    @Published var isSyncing = false
    @Published var isInitialLoading = true
    @Published var lastSyncError: Error?

    init() {}

    func loadCachedDataAsync() {
        Task.detached(priority: .userInitiated) {
            let loadedFolders = StorageService.shared.getSnippets()

            await MainActor.run {
                self.folders = loadedFolders
                self.isInitialLoading = false
            }
        }
    }

    func syncInBackground() {
        guard !isSyncing else { return }

        isSyncing = true
        lastSyncError = nil

        Task {
            await SyncService.shared.syncMasterSnippets()

            await withCheckedContinuation { continuation in
                PersonalSyncService.shared.syncPersonalSnippets { _ in
                    continuation.resume()
                }
            }

            let loadedFolders = StorageService.shared.getSnippets()

            self.folders = loadedFolders
            self.isSyncing = false
        }
    }

    func refresh() async {
        print("🔴 [AppState] refresh() 開始 - isSyncing: \(isSyncing)")
        guard !isSyncing else {
            print("🔴 [AppState] refresh() スキップ（既に同期中）")
            return
        }

        isSyncing = true
        lastSyncError = nil
        print("🔴 [AppState] isSyncing = true")

        print("🔴 [AppState] マスター同期開始")
        await SyncService.shared.syncMasterSnippets()
        print("🔴 [AppState] マスター同期完了")

        print("🔴 [AppState] 個別同期開始")
        await withCheckedContinuation { continuation in
            PersonalSyncService.shared.syncPersonalSnippets { result in
                print("🔴 [AppState] 個別同期結果: \(result)")
                continuation.resume()
            }
        }
        print("🔴 [AppState] 個別同期完了")

        let loadedFolders = StorageService.shared.getSnippets()
        print("🔴 [AppState] フォルダ読み込み: \(loadedFolders.count) フォルダ")

        folders = loadedFolders
        isSyncing = false
        print("🔴 [AppState] refresh() 完了 - isSyncing: \(isSyncing)")
    }
}

// MARK: - App

@main
struct SnipeeIOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onAppear {
                    appState.loadCachedDataAsync()
                }
                .task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    appState.syncInBackground()
                }
        }
    }
}
