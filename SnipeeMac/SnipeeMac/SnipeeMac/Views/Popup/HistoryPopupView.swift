//
//  HistoryPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct HistoryPopupView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @State private var selectedIndex: Int = 0
    @State private var isSubmenuOpen: Bool = false
    @State private var submenuItems: [HistoryItem] = []
    @State private var submenuSelectedIndex: Int = 0
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    private var pinnedItems: [HistoryItem] {
        clipboardService.history.filter { $0.isPinned }
    }
    
    private var unpinnedItems: [HistoryItem] {
        clipboardService.history.filter { !$0.isPinned }
    }
    
    private var historyGroups: [[HistoryItem]] {
        var groups: [[HistoryItem]] = []
        let items = unpinnedItems
        
        // Group 1: 1-15
        if items.count > 0 {
            groups.append(Array(items.prefix(15)))
        }
        // Group 2: 16-30
        if items.count > 15 {
            groups.append(Array(items.dropFirst(15).prefix(15)))
        }
        // Group 3: 31-45
        if items.count > 30 {
            groups.append(Array(items.dropFirst(30).prefix(15)))
        }
        
        return groups
    }
    
    private var groupLabels: [String] {
        ["最近 (1-15)", "少し前 (16-30)", "以前 (31-45)"]
    }
    
    private var totalSelectableCount: Int {
        pinnedItems.count + historyGroups.count + 1 // +1 for clear action
    }
    
    var body: some View {
        mainMenuContent
            .background(theme.backgroundColor)
            .cornerRadius(10)
            .onAppear {
                setupKeyboardHandler()
            }
    }
    
    private var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("履歴")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "e0e0e0"))
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Pinned items (directly selectable)
                        if !pinnedItems.isEmpty {
                            MenuSection(title: "📌 ピン留め", theme: theme)
                            ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                                MenuItemRow(
                                    title: item.content.prefix(30).description,
                                    icon: "📄",
                                    isSelected: selectedIndex == index,
                                    theme: theme
                                ) {
                                    pasteItem(item)
                                }
                                .id(index)
                            }
                            Divider().padding(.vertical, 4)
                        }
                        
                        // History groups
                        if !historyGroups.isEmpty {
                            MenuSection(title: "📋 履歴", theme: theme)
                            ForEach(Array(historyGroups.enumerated()), id: \.offset) { index, group in
                                let globalIndex = pinnedItems.count + index
                                MenuItemRow(
                                    title: groupLabels[index],
                                    subtitle: "\(group.count)",
                                    icon: "📁",
                                    isSelected: selectedIndex == globalIndex,
                                    hasArrow: true,
                                    theme: theme
                                ) {
                                    openSubmenuForGroup(at: index)
                                }
                                .id(globalIndex)
                            }
                        }
                        
                        if pinnedItems.isEmpty && historyGroups.isEmpty {
                            HStack {
                                Text("📄")
                                    .frame(width: 14)
                                    .opacity(0.4)
                                Text("履歴がありません")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                        
                        // Clear action
                        Divider().padding(.vertical, 4)
                        let clearIndex = pinnedItems.count + historyGroups.count
                        MenuItemRow(
                            title: "履歴をクリア",
                            icon: "🗑",
                            isSelected: selectedIndex == clearIndex,
                            isDestructive: true,
                            theme: theme
                        ) {
                            clipboardService.clearHistory()
                        }
                        .id(clearIndex)
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
            HStack(spacing: 14) {
                FooterKey(key: "↑↓", label: "選択")
                FooterKey(key: "▶", label: "展開")
                FooterKey(key: "P", label: "ピン")
                FooterKey(key: "Esc", label: "終了")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: Constants.UI.popupWidth)
    }
    
    private var submenuContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(submenuItems.enumerated()), id: \.element.id) { index, item in
                            Button(action: { pasteItem(item) }) {
                                HStack {
                                    Text("📄")
                                        .frame(width: 16)
                                    Text("\(index + 1).")
                                        .font(.system(size: 11))
                                        .foregroundColor(submenuSelectedIndex == index ? .white : theme.secondaryTextColor)
                                        .frame(width: 20)
                                    Text(item.content.prefix(25).description)
                                        .font(.system(size: 11))
                                        .foregroundColor(submenuSelectedIndex == index ? .white : theme.textColor)
                                        .lineLimit(1)
                                    Spacer()
                                    
                                    Text(item.isPinned ? "●" : "○")
                                        .font(.system(size: 10))
                                        .foregroundColor(submenuSelectedIndex == index ? .white : theme.secondaryTextColor)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(submenuSelectedIndex == index ? theme.accentColor : Color.clear)
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: submenuSelectedIndex) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: Constants.UI.submenuWidth)
        .frame(maxHeight: Constants.UI.submenuMaxHeight)
        .background(theme.backgroundColor)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .leading
        )
    }
    
    // MARK: - Keyboard Handler
    
    private func setupKeyboardHandler() {
        PopupWindowController.shared.onKeyDown = { [self] keyCode in
            if isSubmenuOpen {
                return handleSubmenuKeyDown(keyCode)
            } else {
                return handleMainMenuKeyDown(keyCode)
            }
        }
    }
    
    private func handleMainMenuKeyDown(_ keyCode: UInt16) -> Bool {
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
        case 124: // Right
            let groupStartIndex = pinnedItems.count
            let groupEndIndex = groupStartIndex + historyGroups.count
            if selectedIndex >= groupStartIndex && selectedIndex < groupEndIndex {
                openSubmenuForGroup(at: selectedIndex - groupStartIndex)
            }
            return true
        case 36: // Enter
            executeSelectedItem()
            return true
        case 35: // P key
            togglePinForSelectedItem()
            return true
        default:
            if keyCode >= 101 && keyCode <= 109 {
                let num = Int(keyCode) - 100
                if num <= pinnedItems.count {
                    pasteItem(pinnedItems[num - 1])
                }
                return true
            }
            return false
        }
    }
    
    private func handleSubmenuKeyDown(_ keyCode: UInt16) -> Bool {
        switch keyCode {
        case 126: // Up
            if submenuSelectedIndex > 0 {
                submenuSelectedIndex -= 1
            }
            return true
        case 125: // Down
            if submenuSelectedIndex < submenuItems.count - 1 {
                submenuSelectedIndex += 1
            }
            return true
        case 123: // Left
            closeSubmenu()
            return true
        case 36: // Enter
            if submenuSelectedIndex < submenuItems.count {
                pasteItem(submenuItems[submenuSelectedIndex])
            }
            return true
        case 35: // P key
            togglePinForSubmenuItem()
            return true
        default:
            if keyCode >= 101 && keyCode <= 109 {
                let num = Int(keyCode) - 100
                if num <= submenuItems.count {
                    pasteItem(submenuItems[num - 1])
                }
                return true
            }
            return false
        }
    }
    
    // MARK: - Actions
    
    private func executeSelectedItem() {
        if selectedIndex < pinnedItems.count {
            pasteItem(pinnedItems[selectedIndex])
        } else if selectedIndex < pinnedItems.count + historyGroups.count {
            openSubmenuForGroup(at: selectedIndex - pinnedItems.count)
        } else {
            clipboardService.clearHistory()
        }
    }
    
    private func openSubmenuForGroup(at index: Int) {
        guard index < historyGroups.count else { return }
        
        submenuItems = historyGroups[index]
        submenuSelectedIndex = 0
        isSubmenuOpen = true
        
        showSubmenuWindow()
    }
    
    private func closeSubmenu() {
        isSubmenuOpen = false
        submenuItems = []
        submenuSelectedIndex = 0
        
        PopupWindowController.shared.hideSubmenu()
    }
    
    private func showSubmenuWindow() {
        let content = HistorySubmenuContent(
            items: submenuItems,
            selectedIndex: $submenuSelectedIndex,
            theme: theme,
            onSelect: { item in
                pasteItem(item)
            },
            onTogglePin: { item in
                clipboardService.togglePin(for: item)
            }
        )
        PopupWindowController.shared.showSubmenu(content: content)
    }
    
    private func togglePinForSelectedItem() {
        guard selectedIndex < pinnedItems.count else { return }
        let item = pinnedItems[selectedIndex]
        clipboardService.togglePin(for: item)
    }
    
    private func togglePinForSubmenuItem() {
        guard submenuSelectedIndex < submenuItems.count else { return }
        let item = submenuItems[submenuSelectedIndex]
        clipboardService.togglePin(for: item)
    }
    
    private func pasteItem(_ item: HistoryItem) {
        PopupWindowController.shared.hidePopup()
        PasteService.shared.pasteText(item.content)
    }
}


// MARK: - History Submenu Content

struct HistorySubmenuContent: View {
    let items: [HistoryItem]
    @Binding var selectedIndex: Int
    let theme: ColorTheme
    let onSelect: (HistoryItem) -> Void
    let onTogglePin: (HistoryItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button(action: { onSelect(item) }) {
                                HStack {
                                    Text("📄")
                                        .frame(width: 16)
                                    Text("\(index + 1).")
                                        .font(.system(size: 11))
                                        .foregroundColor(selectedIndex == index ? .white : theme.secondaryTextColor)
                                        .frame(width: 20)
                                    Text(item.content.prefix(25).description)
                                        .font(.system(size: 11))
                                        .foregroundColor(selectedIndex == index ? .white : theme.textColor)
                                        .lineLimit(1)
                                    Spacer()
                                    
                                    Text(item.isPinned ? "●" : "○")
                                        .font(.system(size: 10))
                                        .foregroundColor(selectedIndex == index ? .white : theme.secondaryTextColor)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(selectedIndex == index ? theme.accentColor : Color.clear)
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selectedIndex) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: Constants.UI.submenuWidth)
        .frame(maxHeight: Constants.UI.submenuMaxHeight)
        .background(theme.backgroundColor)
        .cornerRadius(10)
    }
}
