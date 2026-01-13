//
//  MainPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct MainPopupView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @State private var selectedIndex: Int = 0
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    private var pinnedItems: [HistoryItem] {
        clipboardService.history.filter { $0.isPinned }
    }
    
    private var recentItems: [HistoryItem] {
        Array(clipboardService.history.filter { !$0.isPinned }.prefix(5))
    }
    
    private var totalSelectableCount: Int {
        pinnedItems.count + recentItems.count + 4 // 4 action items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📋 Snipee")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Spacer()
                Text("v\(Constants.App.version)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Pinned items
                        let pinnedItems = clipboardService.history.filter { $0.isPinned }
                        if !pinnedItems.isEmpty {
                            MenuSection(title: "📌 ピン留め", theme: theme)
                            ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                                MenuItemRow(
                                    title: item.content.prefix(50).description,
                                    isSelected: selectedIndex == index,
                                    theme: theme
                                ) {
                                    pasteItem(item)
                                }
                                .id(index)
                            }
                            Divider().padding(.vertical, 4)
                        }
                        
                        // Recent history (max 5)
                        if !recentItems.isEmpty {
                            MenuSection(title: "📝 履歴", theme: theme)
                            ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                                let globalIndex = pinnedItems.count + index
                                MenuItemRow(
                                    title: item.content.prefix(50).description,
                                    subtitle: "\(index + 1)",
                                    isSelected: selectedIndex == globalIndex,
                                    theme: theme
                                ) {
                                    pasteItem(item)
                                }
                                .id(globalIndex)
                            }
                            
                            // Show all history link
                            MenuItemRow(
                                title: "すべての履歴を見る...",
                                icon: "📋",
                                isSelected: false,
                                theme: theme
                            ) {
                                PopupWindowController.shared.hidePopup()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    PopupWindowController.shared.showPopup(type: .history)
                                }
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // Actions
                        let actionStartIndex = pinnedItems.count + recentItems.count
                        MenuSection(title: "⚙️ アクション", theme: theme)
                        
                        MenuItemRow(title: "スニペット編集", icon: "✏️", isSelected: selectedIndex == actionStartIndex, theme: theme) {
                            PopupWindowController.shared.hidePopup()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                SnippetEditorWindow.shared.show()
                            }
                        }
                        .id(actionStartIndex)
                        
                        MenuItemRow(title: "履歴をクリア", icon: "🗑", isSelected: selectedIndex == actionStartIndex + 1, theme: theme) {
                            clipboardService.clearHistory()
                        }
                        .id(actionStartIndex + 1)
                        
                        MenuItemRow(title: "設定", icon: "⚙️", isSelected: selectedIndex == actionStartIndex + 2, theme: theme) {
                            PopupWindowController.shared.hidePopup()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NSApp.sendAction(Selector(("openSettings")), to: nil, from: nil)
                            }
                        }
                        .id(actionStartIndex + 2)
                        
                        MenuItemRow(title: "終了", icon: "🚪", isSelected: selectedIndex == actionStartIndex + 3, theme: theme) {
                            NSApp.terminate(nil)
                        }
                        .id(actionStartIndex + 3)
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selectedIndex) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            
            // Footer
            Divider()
            HStack {
                Text("↑↓ 移動  Enter 選択  Esc 閉じる")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: Constants.UI.popupWidth)
        .background(theme.backgroundColor)
        .cornerRadius(10)
        .onAppear {
            setupKeyboardHandler()
        }
    }
    
    private func setupKeyboardHandler() {
        PopupWindowController.shared.onKeyDown = { [self] keyCode in
            switch keyCode {
            case 126: // Up
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return true
            case 125: // Down
                if selectedIndex < totalSelectableCount - 1 {
                    selectedIndex += 1
                }
                return true
            case 36: // Enter
                executeSelectedItem()
                return true
            default:
                // Number keys (101-109)
                if keyCode >= 101 && keyCode <= 109 {
                    let num = Int(keyCode) - 100
                    let targetIndex = pinnedItems.count + num - 1
                    if targetIndex < pinnedItems.count + recentItems.count {
                        let item = recentItems[num - 1]
                        pasteItem(item)
                    }
                    return true
                }
                return false
            }
        }
    }
    
    private func executeSelectedItem() {
        let actionStartIndex = pinnedItems.count + recentItems.count
        
        if selectedIndex < pinnedItems.count {
            pasteItem(pinnedItems[selectedIndex])
        } else if selectedIndex < actionStartIndex {
            let recentIndex = selectedIndex - pinnedItems.count
            pasteItem(recentItems[recentIndex])
        } else {
            switch selectedIndex - actionStartIndex {
            case 0: // スニペット編集
                PopupWindowController.shared.hidePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    SnippetEditorWindow.shared.show()
                }
            case 1: // 履歴をクリア
                clipboardService.clearHistory()
            case 2: // 設定
                PopupWindowController.shared.hidePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.sendAction(Selector(("openSettings")), to: nil, from: nil)
                }
            case 3: // 終了
                NSApp.terminate(nil)
            default:
                break
            }
        }
    }
    
    private func pasteItem(_ item: HistoryItem) {
        PopupWindowController.shared.hidePopup()
        PasteService.shared.pasteText(item.content)
    }
}

// MARK: - Menu Section

struct MenuSection: View {
    let title: String
    let theme: ColorTheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.secondaryTextColor)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Menu Item Row

struct MenuItemRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var isSelected: Bool = false
    let theme: ColorTheme
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Text(icon)
                        .frame(width: 20)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? theme.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
