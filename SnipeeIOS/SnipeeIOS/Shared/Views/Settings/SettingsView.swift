//
//  SettingsView.swift
//  SnipeeIOS
//

import SwiftUI

struct SettingsView: View {
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
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
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
    }

    private func loadSettings() {
        let settings = StorageService.shared.getSettings()
        userName = settings.userName
        lastSyncDate = settings.lastSyncDate
    }

    private func syncNow() {
        Task {
            await SyncService.shared.syncMasterSnippets()
            loadSettings()
        }
    }
}

#Preview {
    SettingsView()
}
