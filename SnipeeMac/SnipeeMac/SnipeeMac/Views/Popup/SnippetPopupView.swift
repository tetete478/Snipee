//
//  SnippetPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct SnippetPopupView: View {
    @State private var selectedIndex: Int = 0
    @State private var isSubmenuOpen: Bool = false
    @State private var submenuItems: [Snippet] = []
    @State private var submenuSelectedIndex: Int = 0
    
    @State private var masterFolders: [SnippetFolder] = []
    @State private var personalFolders: [SnippetFolder] = []
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    private var allFolders: [SnippetFolder] {
        masterFolders + personalFolders
    }
    
    private var totalSelectableCount: Int {
        allFolders.count + 1 // +1 for editor action
    }
    
    var body: some View {
        mainMenuContent
            .background(theme.backgroundColor)
            .cornerRadius(10)
            .onAppear {
                loadSnippets()
                setupKeyboardHandler()
            }
    }
    
    private var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("スニペット")
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
                        // Master snippets
                        if !masterFolders.isEmpty {
                            MenuSection(title: "🏢 マスタ", theme: theme)
                            ForEach(Array(masterFolders.enumerated()), id: \.element.id) { index, folder in
                                MenuItemRow(
                                    title: folder.name,
                                    icon: "📁",
                                    isSelected: selectedIndex == index,
                                    hasArrow: true,
                                    theme: theme
                                ) {
                                    openSubmenuForFolder(at: index)
                                }
                                .id(index)
                            }
                        }
                        
                        // Personal snippets
                        if !personalFolders.isEmpty {
                            MenuSection(title: "👤 個別", theme: theme)
                            ForEach(Array(personalFolders.enumerated()), id: \.element.id) { index, folder in
                                let globalIndex = masterFolders.count + index
                                MenuItemRow(
                                    title: folder.name,
                                    icon: "📁",
                                    isSelected: selectedIndex == globalIndex,
                                    hasArrow: true,
                                    theme: theme
                                ) {
                                    openSubmenuForFolder(at: globalIndex)
                                }
                                .id(globalIndex)
                            }
                        }
                        
                        if masterFolders.isEmpty && personalFolders.isEmpty {
                            HStack {
                                Text("📁")
                                    .frame(width: 14)
                                    .opacity(0.4)
                                Text("スニペットがありません")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                        
                        // Actions
                        Divider().padding(.vertical, 4)
                        let actionIndex = allFolders.count
                        MenuItemRow(
                            title: "スニペット編集",
                            icon: "✏️",
                            isSelected: selectedIndex == actionIndex,
                            theme: theme
                        ) {
                            openSnippetEditor()
                        }
                        .id(actionIndex)
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
    
    private var submenuContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(submenuItems.enumerated()), id: \.element.id) { index, snippet in
                            Button(action: { pasteSnippet(snippet) }) {
                                HStack {
                                    Text("📄")
                                        .frame(width: 16)
                                    Text("\(index + 1).")
                                        .font(.system(size: 11))
                                        .foregroundColor(submenuSelectedIndex == index ? .white : theme.secondaryTextColor)
                                        .frame(width: 20)
                                    Text(snippet.title.prefix(25).description)
                                        .font(.system(size: 11))
                                        .foregroundColor(submenuSelectedIndex == index ? .white : theme.textColor)
                                        .lineLimit(1)
                                    Spacer()
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
    
    // MARK: - Data Loading
    
    private func loadSnippets() {
        masterFolders = StorageService.shared.getMasterSnippets()
        personalFolders = StorageService.shared.getPersonalSnippets()
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
            if selectedIndex < allFolders.count {
                openSubmenuForFolder(at: selectedIndex)
            }
            return true
        case 36: // Enter
            executeSelectedItem()
            return true
        default:
            if keyCode >= 101 && keyCode <= 109 {
                let num = Int(keyCode) - 100
                if num <= allFolders.count {
                    selectedIndex = num - 1
                    openSubmenuForFolder(at: selectedIndex)
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
                pasteSnippet(submenuItems[submenuSelectedIndex])
            }
            return true
        default:
            if keyCode >= 101 && keyCode <= 109 {
                let num = Int(keyCode) - 100
                if num <= submenuItems.count {
                    pasteSnippet(submenuItems[num - 1])
                }
                return true
            }
            return false
        }
    }
    
    // MARK: - Actions
    
    private func executeSelectedItem() {
        if selectedIndex < allFolders.count {
            openSubmenuForFolder(at: selectedIndex)
        } else {
            openSnippetEditor()
        }
    }
    
    private func openSubmenuForFolder(at index: Int) {
        guard index < allFolders.count else { return }
        
        let folder = allFolders[index]
        submenuItems = folder.snippets
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
    
    private func pasteSnippet(_ snippet: Snippet) {
        PopupWindowController.shared.hidePopup()
        let content = VariableService.shared.processVariables(snippet.content)
        PasteService.shared.pasteText(content)
    }
    
    private func openSnippetEditor() {
        PopupWindowController.shared.hidePopup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SnippetEditorWindow.shared.show()
        }
    }
}
