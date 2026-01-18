//
//  HelpTab.swift
//  SnipeeMac
//

import SwiftUI

struct HelpTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 変数リスト
            variablesSection
            
            // ホットキー一覧
            hotkeysSection
        }
    }
    
    // MARK: - Variables Section
    private var variablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 変数リスト")
                .font(.headline)
            
            Text("スニペット内で以下の変数を使うと、貼り付け時に自動で置換されます。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 6) {
                // 基本
                variableRow(
                    variable: "{名前}",
                    example: "山田",
                    description: "設定で登録した名前"
                )
                variableRow(
                    variable: "{タイムスタンプ}",
                    example: timestampFormatted(),
                    description: "年月日＋時分秒"
                )
                
                Divider().padding(.vertical, 4)
                
                // 当日・1日後セット
                Text("当日・1日後セット")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                variableRow(
                    variable: "{今日:MM/DD}",
                    example: dayFormatted(0, format: "MM/dd"),
                    description: "今日"
                )
                variableRow(
                    variable: "{明日:MM/DD}",
                    example: dayFormatted(1, format: "MM/dd"),
                    description: "明日"
                )
                variableRow(
                    variable: "{今日:M月D日:曜日短}",
                    example: dayFormattedJP(0),
                    description: "今日（日本語）"
                )
                variableRow(
                    variable: "{明日:M月D日:曜日短}",
                    example: dayFormattedJP(1),
                    description: "明日（日本語）"
                )
                
                Divider().padding(.vertical, 4)
                
                // 1日後・2日後セット
                Text("1日後・2日後セット")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                variableRow(
                    variable: "{明日:MM/DD}",
                    example: dayFormatted(1, format: "MM/dd"),
                    description: "1日後"
                )
                variableRow(
                    variable: "{2日後:MM/DD}",
                    example: dayFormatted(2, format: "MM/dd"),
                    description: "2日後"
                )
                variableRow(
                    variable: "{明日:M月D日:曜日短}",
                    example: dayFormattedJP(1),
                    description: "1日後（日本語）"
                )
                variableRow(
                    variable: "{2日後:M月D日:曜日短}",
                    example: dayFormattedJP(2),
                    description: "2日後（日本語）"
                )
                
                Divider().padding(.vertical, 4)
                
                // 2日後・3日後セット
                Text("2日後・3日後セット")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                variableRow(
                    variable: "{2日後:MM/DD}",
                    example: dayFormatted(2, format: "MM/dd"),
                    description: "2日後"
                )
                variableRow(
                    variable: "{3日後:MM/DD}",
                    example: dayFormatted(3, format: "MM/dd"),
                    description: "3日後"
                )
                variableRow(
                    variable: "{2日後:M月D日:曜日短}",
                    example: dayFormattedJP(2),
                    description: "2日後（日本語）"
                )
                variableRow(
                    variable: "{3日後:M月D日:曜日短}",
                    example: dayFormattedJP(3),
                    description: "3日後（日本語）"
                )
                
                Divider().padding(.vertical, 4)
                
                // 1日除外パターン
                Text("1日除外パターン")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                variableRow(
                    variable: "{2日後:M月D日:曜日短（毎月1日は除外して3日後）}",
                    example: dayFormattedJP(2),
                    description: "2日後（1日除外）"
                )
                variableRow(
                    variable: "{3日後:M月D日:曜日短（毎月1日は除外して4日後）}",
                    example: dayFormattedJP(3),
                    description: "3日後（1日除外）"
                )
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func variableRow(variable: String, example: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(variable)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 180, alignment: .leading)
            
            Text(example)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Hotkeys Section
    private var hotkeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⌨️ ホットキー一覧")
                .font(.headline)
            
            Text("いつでもSnipeeを呼び出せます。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                hotkeyRow(
                    keys: ["⌘", "⌃", "C"],
                    name: "簡易ホーム",
                    description: "履歴とスニペットを一覧表示"
                )
                hotkeyRow(
                    keys: ["⌘", "⌃", "V"],
                    name: "スニペット専用",
                    description: "スニペットのみを表示"
                )
                hotkeyRow(
                    keys: ["⌘", "⌃", "X"],
                    name: "履歴専用",
                    description: "クリップボード履歴のみを表示"
                )
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func hotkeyRow(keys: [String], name: String, description: String) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.controlColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 80, alignment: .leading)
            
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 100, alignment: .leading)
            
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Date Helpers
    private func timestampFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func dayFormatted(_ days: Int, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func dayFormattedJP(_ days: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
