
//
//  HistoryPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct HistoryPopupView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @State private var selectedIndex: Int = 0
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📋 履歴")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Spacer()
                Button(action: { clipboardService.clearHistory() }) {
                    Text("クリア")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Pinned items
                    let pinnedItems = clipboardService.history.filter { $0.isPinned }
                    if !pinnedItems.isEmpty {
                        MenuSection(title: "📌 ピン留め", theme: theme)
                        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                            HistoryItemRow(item: item, index: nil, theme: theme) {
                                pasteItem(item)
                            } onTogglePin: {
                                clipboardService.togglePin(for: item)
                            }
                        }
                        Divider().padding(.vertical, 4)
                    }
                    
                    // All history grouped
                    let unpinnedItems = clipboardService.history.filter { !$0.isPinned }
                    
                    // Group 1: 1-15
                    let group1 = Array(unpinnedItems.prefix(15))
                    if !group1.isEmpty {
                        MenuSection(title: "最近 (1-15)", theme: theme)
                        ForEach(Array(group1.enumerated()), id: \.element.id) { index, item in
                            HistoryItemRow(item: item, index: index + 1, theme: theme) {
                                pasteItem(item)
                            } onTogglePin: {
                                clipboardService.togglePin(for: item)
                            }
                        }
                    }
                    
                    // Group 2: 16-30
                    let group2 = Array(unpinnedItems.dropFirst(15).prefix(15))
                    if !group2.isEmpty {
                        Divider().padding(.vertical, 4)
                        MenuSection(title: "少し前 (16-30)", theme: theme)
                        ForEach(Array(group2.enumerated()), id: \.element.id) { index, item in
                            HistoryItemRow(item: item, index: index + 16, theme: theme) {
                                pasteItem(item)
                            } onTogglePin: {
                                clipboardService.togglePin(for: item)
                            }
                        }
                    }
                    
                    // Group 3: 31-45
                    let group3 = Array(unpinnedItems.dropFirst(30).prefix(15))
                    if !group3.isEmpty {
                        Divider().padding(.vertical, 4)
                        MenuSection(title: "以前 (31-45)", theme: theme)
                        ForEach(Array(group3.enumerated()), id: \.element.id) { index, item in
                            HistoryItemRow(item: item, index: index + 31, theme: theme) {
                                pasteItem(item)
                            } onTogglePin: {
                                clipboardService.togglePin(for: item)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Footer
            Divider()
            HStack {
                Text("↑↓ 移動  Enter 選択  P ピン留め  Esc 閉じる")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: Constants.UI.popupWidth)
        .background(theme.backgroundColor)
        .cornerRadius(10)
    }
    
    private func pasteItem(_ item: HistoryItem) {
        PopupWindowController.shared.hidePopup()
        PasteService.shared.pasteText(item.content)
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem
    let index: Int?
    let theme: ColorTheme
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    if let index = index {
                        Text("\(index)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(width: 24)
                    }
                    
                    Text(item.content.prefix(50).description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Button(action: onTogglePin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.caption)
                    .foregroundColor(item.isPinned ? theme.accentColor : theme.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}
