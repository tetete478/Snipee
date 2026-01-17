//
//  MainPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct MainPopupView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @State private var selectedIndex: Int = 0
    @State private var isSubmenuOpen: Bool = false
    @State private var submenuItems: [Snippet] = []
    @State private var historySubmenuItems: [HistoryItem] = []
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
        
        if items.count > 0 {
            groups.append(Array(items.prefix(15)))
        }
        if items.count > 15 {
            groups.append(Array(items.dropFirst(15).prefix(15)))
        }
        if items.count > 30 {
            groups.append(Array(items.dropFirst(30).prefix(15)))
        }
        
        return groups
    }

    private var groupLabels: [String] {
        ["最近 (1-15)", "少し前 (16-30)", "以前 (31-45)"]
    }
    
    private var snippetFolders: [SnippetFolder] {
        StorageService.shared.getPersonalSnippets() + StorageService.shared.getMasterSnippets()
    }
    
    private var totalSelectableCount: Int {
        pinnedItems.count + historyGroups.count + snippetFolders.count + 4
    }
    
    var body: some View {
        mainMenuContent
            .background(theme.backgroundColor)
            .cornerRadius(10)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                setupKeyboardHandler()
            }
    }

    private var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Snipee")
                    .font(.system(size: Constants.FontSize.body, weight: .semibold))
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
                                    openHistorySubmenu(at: index)
                                }
                                .id(globalIndex)
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // Snippet folders section
                        MenuSection(title: "スニペット", theme: theme)
                        if snippetFolders.isEmpty {
                            HStack {
                                Text("📁")
                                    .frame(width: 14)
                                    .opacity(0.4)
                                Text("スニペットがありません")
                                    .font(.system(size: Constants.FontSize.body))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        } else {
                            ForEach(Array(snippetFolders.enumerated()), id: \.element.id) { index, folder in
                                let globalIndex = pinnedItems.count + historyGroups.count + index
                                MenuItemRow(
                                    title: folder.name,
                                    icon: "📁",
                                    isSelected: selectedIndex == globalIndex,
                                    hasArrow: true,
                                    theme: theme
                                ) {
                                    // TODO: Show submenu
                                }
                                .id(globalIndex)
                            }
                        }
                                                
                        Divider().padding(.vertical, 4)
                        
                        // Actions
                        let actionStartIndex = pinnedItems.count + historyGroups.count + snippetFolders.count
                        MenuSection(title: "⚙️ アクション", theme: theme)
                        
                        MenuItemRow(title: "スニペット編集", icon: "✏️", isSelected: selectedIndex == actionStartIndex, theme: theme) {
                            PopupWindowController.shared.hidePopup()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                SnippetEditorWindow.shared.show()
                            }
                        }
                        .id(actionStartIndex)
                        
                        MenuItemRow(title: "履歴をクリア", icon: "🗑", isSelected: selectedIndex == actionStartIndex + 1, theme: theme) {
                            confirmClearHistory()
                        }
                        .id(actionStartIndex + 1)
                        
                        MenuItemRow(title: "設定", icon: "⚙️", isSelected: selectedIndex == actionStartIndex + 2, theme: theme) {
                            PopupWindowController.shared.hidePopup()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NSApp.sendAction(Selector(("openSettings")), to: nil, from: nil)
                            }
                        }
                        .id(actionStartIndex + 2)
                        
                        MenuItemRow(title: "Snipeeを終了", icon: "×", isSelected: selectedIndex == actionStartIndex + 3, isDestructive: true, theme: theme) {
                            confirmQuitApp()
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
            HStack(spacing: 14) {
                FooterKey(key: "↑↓", label: "選択")
                FooterKey(key: "▶", label: "展開")
                FooterKey(key: "◀", label: "閉じる")
                FooterKey(key: "Esc", label: "終了")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: Constants.UI.popupWidth)
        
    }
    
    private func showSubmenuWindow() {
    let content = SubmenuWindowContent(
        items: submenuItems,
        selectedIndex: $submenuSelectedIndex,
        theme: theme,
        onSelect: { snippet in
            pasteSnippet(snippet)
        }
    )
    PopupWindowController.shared.showSubmenu(content: content)
}
    // 修正後
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
            selectedIndex = NavigationHelper.loopIndex(selectedIndex, delta: -1, count: totalSelectableCount)
            return true
        case 125: // Down
            selectedIndex = NavigationHelper.loopIndex(selectedIndex, delta: 1, count: totalSelectableCount)
            return true
        case 124: // Right - サブメニュー展開
            let historyStartIndex = pinnedItems.count
            let historyEndIndex = historyStartIndex + historyGroups.count
            let folderEndIndex = historyEndIndex + snippetFolders.count
            
            if selectedIndex >= historyStartIndex && selectedIndex < historyEndIndex {
                openHistorySubmenu(at: selectedIndex - historyStartIndex)
            } else if selectedIndex >= historyEndIndex && selectedIndex < folderEndIndex {
                openSubmenuForSelectedFolder()
            }
            return true
        case 36: // Enter
            executeSelectedItem()
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
        let isHistorySubmenu = !historySubmenuItems.isEmpty
        let itemCount = isHistorySubmenu ? historySubmenuItems.count : submenuItems.count
        
        switch keyCode {
        case 126: // Up
            if submenuSelectedIndex > 0 {
                submenuSelectedIndex -= 1
            } else {
                submenuSelectedIndex = itemCount - 1
            }
            return true
        case 125: // Down
            if submenuSelectedIndex < itemCount - 1 {
                submenuSelectedIndex += 1
            } else {
                submenuSelectedIndex = 0
            }
            return true
        case 123: // Left - サブメニュー閉じる
            closeSubmenu()
            return true
        case 36: // Enter
            if isHistorySubmenu {
                if submenuSelectedIndex < historySubmenuItems.count {
                    pasteItem(historySubmenuItems[submenuSelectedIndex])
                }
            } else {
                if submenuSelectedIndex < submenuItems.count {
                    pasteSnippet(submenuItems[submenuSelectedIndex])
                }
            }
            return true
        default:
            if keyCode >= 101 && keyCode <= 109 {
                let num = Int(keyCode) - 100
                if isHistorySubmenu {
                    if num <= historySubmenuItems.count {
                        pasteItem(historySubmenuItems[num - 1])
                    }
                } else {
                    if num <= submenuItems.count {
                        pasteSnippet(submenuItems[num - 1])
                    }
                }
                return true
            }
            return false
        }
    }
    
    private func executeSelectedItem() {
    let historyEndIndex = pinnedItems.count + historyGroups.count
    let folderEndIndex = historyEndIndex + snippetFolders.count
    
    if selectedIndex < pinnedItems.count {
        pasteItem(pinnedItems[selectedIndex])
    } else if selectedIndex < historyEndIndex {
        let groupIndex = selectedIndex - pinnedItems.count
        openHistorySubmenu(at: groupIndex)
    } else if selectedIndex < folderEndIndex {
            // フォルダ選択時はサブメニューを開く
            openSubmenuForSelectedFolder()
        } else {
            switch selectedIndex - folderEndIndex {
            case 0: // スニペット編集
                PopupWindowController.shared.hidePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    SnippetEditorWindow.shared.show()
                }
            case 1: // 履歴をクリア
                confirmClearHistory()
            case 2: // 設定
                PopupWindowController.shared.hidePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.sendAction(Selector(("openSettings")), to: nil, from: nil)
                }
            case 3: // 終了
                confirmQuitApp()
            default:
                break
            }
        }
    }
    
    private func pasteItem(_ item: HistoryItem) {
        PopupWindowController.shared.hidePopup()
        PasteService.shared.pasteText(item.content)
    }

    private func pasteSnippet(_ snippet: Snippet) {
        PopupWindowController.shared.hidePopup()
        let content = VariableService.shared.processVariables(snippet.content)
        PasteService.shared.pasteText(content)
    }

    private func openSubmenuForSelectedFolder() {
        let folderStartIndex = pinnedItems.count + historyGroups.count
        let folderEndIndex = folderStartIndex + snippetFolders.count
        
        guard selectedIndex >= folderStartIndex && selectedIndex < folderEndIndex else { return }
        
        let folderIndex = selectedIndex - folderStartIndex
        let folder = snippetFolders[folderIndex]
        
        submenuItems = folder.snippets
        submenuSelectedIndex = 0
        isSubmenuOpen = true
        
        showSubmenuWindow()
    }

    private func closeSubmenu() {
        isSubmenuOpen = false
        submenuItems = []
        historySubmenuItems = []
        submenuSelectedIndex = 0
        
        PopupWindowController.shared.hideSubmenu()
    }
    
    private func confirmClearHistory() {
        let alert = NSAlert()
        alert.messageText = "履歴をクリア"
        alert.informativeText = "すべての履歴を削除しますか？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "クリア")
        alert.addButton(withTitle: "キャンセル")
        
        if alert.runModal() == .alertFirstButtonReturn {
            clipboardService.clearHistory()
        }
    }

    private func confirmQuitApp() {
        let alert = NSAlert()
        alert.messageText = "Snipeeを終了"
        alert.informativeText = "Snipeeを終了しますか？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "終了")
        alert.addButton(withTitle: "キャンセル")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }
    
    private func openHistorySubmenu(at index: Int) {
        guard index < historyGroups.count else { return }
        
        historySubmenuItems = historyGroups[index]
        submenuSelectedIndex = 0
        isSubmenuOpen = true
        
        showHistorySubmenuWindow()
    }

    private func showHistorySubmenuWindow() {
        let content = HistorySubmenuContent(
            items: historySubmenuItems,
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
}

// MARK: - Menu Section

struct MenuSection: View {
    let title: String
    let theme: ColorTheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: Constants.FontSize.caption, weight: .semibold))
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
    var hasArrow: Bool = false
    var isDestructive: Bool = false
    let theme: ColorTheme
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Text(icon)
                        .frame(width: 20)
                        .foregroundColor(isSelected ? .white : (isDestructive ? .red : theme.textColor))
                }
                
                Text(title)
                    .font(.system(size: Constants.FontSize.body))
                    .foregroundColor(isSelected ? .white : (isDestructive ? .red : theme.textColor))
                    .lineLimit(1)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: Constants.FontSize.caption))
                        .foregroundColor(isSelected ? .white : theme.secondaryTextColor)
                        .frame(width: 20)
                }
                
                if hasArrow {
                    Text(">")
                        .font(.system(size: Constants.FontSize.caption))
                        .foregroundColor(isSelected ? .white : .gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isSelected ? theme.accentColor : Color.clear)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}


// MARK: - Footer Key

struct FooterKey: View {
    let key: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.white)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            Text(label)
                .font(.system(size: Constants.FontSize.caption))
                .foregroundColor(.gray)
        }
    }
}


// MARK: - Submenu Window Content

struct SubmenuWindowContent: View {
    let items: [Snippet]
    @Binding var selectedIndex: Int
    let theme: ColorTheme
    let onSelect: (Snippet) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if items.isEmpty {
                            HStack {
                                Text("📄")
                                    .frame(width: 16)
                                    .opacity(0.4)
                                Text("スニペットがありません")
                                    .font(.system(size: Constants.FontSize.body))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, snippet in
                            Button(action: { onSelect(snippet) }) {
                                HStack {
                                    Text("📄")
                                        .frame(width: 16)
                                    Text("\(index + 1).")
                                        .font(.system(size: Constants.FontSize.caption))
                                        .foregroundColor(selectedIndex == index ? .white : theme.secondaryTextColor)
                                        .frame(width: 20)
                                    Text(snippet.title.prefix(25).description)
                                        .font(.system(size: Constants.FontSize.caption))
                                        .foregroundColor(selectedIndex == index ? .white : theme.textColor)
                                        .lineLimit(1)
                                    Spacer()
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
        .background(theme.backgroundColor)
        .cornerRadius(10)
    }
}
