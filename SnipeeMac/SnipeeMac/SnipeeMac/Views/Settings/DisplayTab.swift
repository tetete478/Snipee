
//
//  DisplayTab.swift
//  SnipeeMac
//

import SwiftUI

struct DisplayTab: View {
    @State private var settings = StorageService.shared.getSettings()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Theme
            VStack(alignment: .leading, spacing: 8) {
                Text("テーマカラー")
                    .font(.headline)
                ThemePicker(selectedTheme: $settings.theme)
                Text("現在: \(ColorTheme(rawValue: settings.theme)?.displayName ?? "シルバー")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Hotkeys
            VStack(alignment: .leading, spacing: 12) {
                Text("ホットキー")
                    .font(.headline)
                
                HStack {
                    Text("メインウィンドウ:")
                        .frame(width: 140, alignment: .leading)
                    Text("⌘ + ⌃ + C")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("スニペット:")
                        .frame(width: 140, alignment: .leading)
                    Text("⌘ + ⌃ + V")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("履歴:")
                        .frame(width: 140, alignment: .leading)
                    Text("⌘ + ⌃ + X")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Divider()
            
            // Paste Delay
            VStack(alignment: .leading, spacing: 8) {
                Text("ペースト遅延")
                    .font(.headline)
                
                HStack {
                    Slider(value: Binding(
                        get: { Double(settings.pasteDelay) },
                        set: { settings.pasteDelay = Int($0) }
                    ), in: 0...200, step: 10)
                    .frame(width: 200)
                    
                    Text("\(settings.pasteDelay) ms")
                        .frame(width: 60)
                }
                
                Text("自動ペーストがうまくいかない場合は値を大きくしてください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onChange(of: settings.theme) { saveSettings() }
        .onChange(of: settings.pasteDelay) { saveSettings() }
    }
    
    private func saveSettings() {
        StorageService.shared.saveSettings(settings)
    }
}
