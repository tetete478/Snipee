//
//  SettingsView.swift
//  SnipeeIOS
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var userName: String = ""
    @State private var lastSyncDate: Date?

    var body: some View {
        NavigationStack {
            List {
                Section("ユーザー") {
                    HStack {
                        Text("名前")
                        Spacer()
                        Text(userName)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: AccountView()) {
                        Text("アカウント")
                    }
                }

                Section("同期") {
                    HStack {
                        Text("最終同期")
                        Spacer()
                        if let date = lastSyncDate {
                            Text(date, style: .relative)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未同期")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: syncNow) {
                        HStack {
                            Text("今すぐ同期")
                            Spacer()
                            if appState.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(appState.isSyncing)
                }

                Section("情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: appState.isSyncing) { _, newValue in
            if !newValue {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
        let settings = StorageService.shared.getSettings()
        userName = settings.userName
        lastSyncDate = settings.lastSyncDate
    }

    private func syncNow() {
        print("🔴🔴🔴 [Settings] 今すぐ同期ボタン押下 🔴🔴🔴")
        Task {
            await appState.refresh()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
