
//
//  GeneralTab.swift
//  SnipeeMac
//

import SwiftUI

struct GeneralTab: View {
    @State private var settings = StorageService.shared.getSettings()
    @State private var launchAtLogin = false
    @State private var updateStatus: String = ""
    @State private var isCheckingUpdate = false
    @State private var hotkeyMainCode: UInt16 = 8
    @State private var hotkeyMainMod: UInt = 0x40101
    @State private var hotkeySnippetCode: UInt16 = 9
    @State private var hotkeySnippetMod: UInt = 0x40101
    @State private var hotkeyHistoryCode: UInt16 = 7
    @State private var hotkeyHistoryMod: UInt = 0x40101
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // User Name
            VStack(alignment: .leading, spacing: 8) {
                Text("ユーザー名")
                    .font(.headline)
                TextField("名前を入力", text: $settings.userName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                Text("スニペットの {名前} 変数に使用されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Launch at Login
            VStack(alignment: .leading, spacing: 8) {
                Toggle("ログイン時に起動", isOn: $launchAtLogin)
                Text("Mac起動時にSnipeeを自動起動します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // History Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("履歴設定")
                    .font(.headline)
                
                HStack {
                    Text("最大履歴数:")
                    TextField("", value: $settings.historyMaxCount, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("件")
                }
            }
            
            Divider()
                        
                        // Hotkey Settings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ホットキー設定")
                                .font(.headline)
                            
                            HotkeyField(
                                label: "メイン:",
                                keyCode: $hotkeyMainCode,
                                modifiers: $hotkeyMainMod
                            )
                            
                            HotkeyField(
                                label: "スニペット:",
                                keyCode: $hotkeySnippetCode,
                                modifiers: $hotkeySnippetMod
                            )
                            
                            HotkeyField(
                                label: "履歴:",
                                keyCode: $hotkeyHistoryCode,
                                modifiers: $hotkeyHistoryMod
                            )
                            
                            Text("クリックしてキーを入力してください")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Links
            VStack(alignment: .leading, spacing: 8) {
                Text("リンク")
                    .font(.headline)
                
                Link("📖 使い方マニュアル", destination: URL(string: "https://github.com/tetete478/snipee")!)
                Link("🐛 バグ報告", destination: URL(string: "https://github.com/tetete478/snipee/issues")!)
            }
            
            Divider()
            
            // Onboarding
            VStack(alignment: .leading, spacing: 8) {
                Text("セットアップ")
                    .font(.headline)
                
                Button(action: {
                    OnboardingWindow.shared.show()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("セットアップを再表示")
                    }
                }
            }
            
            Divider()
            
            // Update
            VStack(alignment: .leading, spacing: 8) {
                Text("アップデート")
                    .font(.headline)
                
                HStack {
                    Button(action: {
                        checkForUpdates()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("アップデートを確認")
                        }
                    }
                    .disabled(isCheckingUpdate)
                    
                    Text("v\(Constants.App.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !updateStatus.isEmpty {
                    Text(updateStatus)
                        .font(.caption)
                        .foregroundColor(updateStatus.contains("エラー") ? .red : .green)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateCheckCompleted)) { notification in
                isCheckingUpdate = false
                if let status = notification.userInfo?["status"] as? String {
                    updateStatus = status
                }
            }
            
            Spacer()
        }
        .onChange(of: settings.userName) { _, _ in saveSettings() }
            .onChange(of: settings.historyMaxCount) { _, _ in saveSettings() }
            .onChange(of: hotkeyMainCode) { _, _ in saveHotkeys() }
            .onChange(of: hotkeyMainMod) { _, _ in saveHotkeys() }
            .onChange(of: hotkeySnippetCode) { _, _ in saveHotkeys() }
            .onChange(of: hotkeySnippetMod) { _, _ in saveHotkeys() }
            .onChange(of: hotkeyHistoryCode) { _, _ in saveHotkeys() }
            .onChange(of: hotkeyHistoryMod) { _, _ in saveHotkeys() }
            .onAppear {
                loadHotkeys()
            }
        }
    
    private func saveSettings() {
        StorageService.shared.saveSettings(settings)
    }

    private func loadHotkeys() {
        hotkeyMainCode = settings.hotkeyMain.keyCode
        hotkeyMainMod = settings.hotkeyMain.modifiers
        hotkeySnippetCode = settings.hotkeySnippet.keyCode
        hotkeySnippetMod = settings.hotkeySnippet.modifiers
        hotkeyHistoryCode = settings.hotkeyHistory.keyCode
        hotkeyHistoryMod = settings.hotkeyHistory.modifiers
    }

    private func saveHotkeys() {
        settings.hotkeyMain = HotkeyConfig(keyCode: hotkeyMainCode, modifiers: hotkeyMainMod)
        settings.hotkeySnippet = HotkeyConfig(keyCode: hotkeySnippetCode, modifiers: hotkeySnippetMod)
        settings.hotkeyHistory = HotkeyConfig(keyCode: hotkeyHistoryCode, modifiers: hotkeyHistoryMod)
        StorageService.shared.saveSettings(settings)
        
        // ホットキーサービスを再起動
        HotkeyService.shared.stopListening()
        HotkeyService.shared.startListening()
    }
    
    private func checkForUpdates() {
        isCheckingUpdate = true
        updateStatus = "確認中..."
        print("🔄 GeneralTab checkForUpdates called")
        if let appDelegate = AppDelegate.shared {
            print("🔄 AppDelegate found, calling checkForUpdates")
            appDelegate.checkForUpdates()
        } else {
            print("🔄 AppDelegate NOT found!")
            updateStatus = "エラー: AppDelegateが見つかりません"
            isCheckingUpdate = false
        }
    }
}
