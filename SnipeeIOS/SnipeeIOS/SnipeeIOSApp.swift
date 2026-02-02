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
    @Published var isInitialLoading = true  // ローディング状態を明示
    @Published var lastSyncError: Error?

    init() {
        print("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴")
        print("🔴 [AppState] init() 開始")
        print("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴")
        // init では何もしない - 重い処理を避ける
    }

    /// キャッシュからデータを読み込み（バックグラウンドで実行）
    func loadCachedDataAsync() {
        print("📱 [AppState] loadCachedDataAsync() 開始")

        // バックグラウンドで読み込み、結果をメインスレッドで反映
        Task.detached(priority: .userInitiated) {
            let loadedFolders = StorageService.shared.getSnippets()
            print("📱 [AppState] キャッシュ読み込み完了: \(loadedFolders.count) フォルダ")

            await MainActor.run {
                self.folders = loadedFolders
                self.isInitialLoading = false
                print("📱 [AppState] UI更新完了")
            }
        }
    }

    /// バックグラウンドで同期を実行
    func syncInBackground() {
        print("🔴🔴🔴 [AppState] syncInBackground() 呼び出し 🔴🔴🔴")

        guard !isSyncing else {
            print("⚠️ [AppState] 同期中のためスキップ")
            return
        }

        print("🔴 [AppState] syncInBackground() 開始")
        isSyncing = true
        lastSyncError = nil

        Task.detached(priority: .utility) {
            print("🔴 [AppState] Task.detached 内部開始")

            // syncMasterSnippets でメンバー情報も取得される
            await SyncService.shared.syncMasterSnippets()

            // 結果をメインスレッドで反映
            let loadedFolders = StorageService.shared.getSnippets()
            print("🔴 [AppState] 同期後のフォルダ数: \(loadedFolders.count)")

            await MainActor.run {
                self.folders = loadedFolders
                self.isSyncing = false
                print("✅✅✅ [AppState] syncInBackground() 完了")
            }
        }
    }

    /// 手動リフレッシュ用
    func refresh() async {
        print("🔴🔴🔴 [AppState] refresh() 呼び出し 🔴🔴🔴")

        guard !isSyncing else {
            print("⚠️ [AppState] 同期中のためスキップ")
            return
        }

        print("🔴 [AppState] refresh() 開始")
        isSyncing = true
        lastSyncError = nil

        // syncMasterSnippets でメンバー情報も取得される
        await SyncService.shared.syncMasterSnippets()

        // バックグラウンドで読み込み
        let loadedFolders = await Task.detached {
            StorageService.shared.getSnippets()
        }.value

        folders = loadedFolders
        isSyncing = false
        print("✅✅✅ [AppState] refresh() 完了: \(folders.count) フォルダ")
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
                    print("📱 [App] MainTabView onAppear")
                    // 画面表示と同時にキャッシュを非同期で読み込み
                    appState.loadCachedDataAsync()
                }
                .task {
                    // 少し待ってからバックグラウンド同期
                    print("🔴🔴🔴 [App] .task 開始 🔴🔴🔴")
                    try? await Task.sleep(for: .milliseconds(300))
                    print("🔴 [App] sleep 完了、syncInBackground 呼び出し")
                    appState.syncInBackground()
                }
        }
    }
}
