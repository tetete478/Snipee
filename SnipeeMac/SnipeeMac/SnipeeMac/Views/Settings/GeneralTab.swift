
//
//  GeneralTab.swift
//  SnipeeMac
//

import SwiftUI

struct GeneralTab: View {
    @State private var settings = StorageService.shared.getSettings()
    @State private var launchAtLogin = false
    
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
            
            // Links
            VStack(alignment: .leading, spacing: 8) {
                Text("リンク")
                    .font(.headline)
                
                Link("📖 使い方マニュアル", destination: URL(string: "https://github.com/tetete478/snipee")!)
                Link("🐛 バグ報告", destination: URL(string: "https://github.com/tetete478/snipee/issues")!)
            }
            
            Spacer()
        }
        .onChange(of: settings.userName) { saveSettings() }
        .onChange(of: settings.historyMaxCount) { saveSettings() }
    }
    
    private func saveSettings() {
        StorageService.shared.saveSettings(settings)
    }
}
