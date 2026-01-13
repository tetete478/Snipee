
//
//  ThemePicker.swift
//  SnipeeMac
//

import SwiftUI

struct ThemePicker: View {
    @Binding var selectedTheme: String
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ColorTheme.allCases, id: \.rawValue) { theme in
                Circle()
                    .fill(theme.backgroundColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(theme.accentColor, lineWidth: selectedTheme == theme.rawValue ? 2 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        selectedTheme = theme.rawValue
                    }
                    .help(theme.displayName)
            }
        }
    }
}

struct ThemePickerRow: View {
    @Binding var selectedTheme: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("テーマカラー")
                .font(.headline)
            
            ThemePicker(selectedTheme: $selectedTheme)
            
            Text(ColorTheme(rawValue: selectedTheme)?.displayName ?? "シルバー")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
