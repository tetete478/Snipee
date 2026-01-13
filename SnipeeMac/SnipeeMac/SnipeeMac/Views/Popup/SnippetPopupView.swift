
//
//  SnippetPopupView.swift
//  SnipeeMac
//

import SwiftUI

struct SnippetPopupView: View {
    @State private var masterFolders: [SnippetFolder] = []
    @State private var personalFolders: [SnippetFolder] = []
    @State private var selectedFolderIndex: Int? = nil
    @State private var selectedSnippetIndex: Int? = nil
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📝 スニペット")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Master snippets
                    if !masterFolders.isEmpty {
                        MenuSection(title: "🏢 マスタスニペット", theme: theme)
                        ForEach(masterFolders) { folder in
                            FolderRow(folder: folder, theme: theme) { snippet in
                                pasteSnippet(snippet)
                            }
                        }
                        Divider().padding(.vertical, 4)
                    }
                    
                    // Personal snippets
                    if !personalFolders.isEmpty {
                        MenuSection(title: "👤 個別スニペット", theme: theme)
                        ForEach(personalFolders) { folder in
                            FolderRow(folder: folder, theme: theme) { snippet in
                                pasteSnippet(snippet)
                            }
                        }
                    }
                    
                    if masterFolders.isEmpty && personalFolders.isEmpty {
                        Text("スニペットがありません")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                            .padding()
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Footer
            Divider()
            HStack {
                Text("↑↓ 移動  → 展開  Esc 閉じる")
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
            loadSnippets()
        }
    }
    
    private func loadSnippets() {
        masterFolders = StorageService.shared.getMasterSnippets()
        personalFolders = StorageService.shared.getPersonalSnippets()
    }
    
    private func pasteSnippet(_ snippet: Snippet) {
        PopupWindowController.shared.hidePopup()
        PasteService.shared.pasteText(snippet.content)
    }
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: SnippetFolder
    let theme: ColorTheme
    let onSelect: (Snippet) -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("📁")
                        .frame(width: 20)
                    Text(folder.name)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textColor)
                    Spacer()
                    Text("\(folder.snippets.count)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            
            if isExpanded {
                ForEach(folder.snippets) { snippet in
                    Button(action: { onSelect(snippet) }) {
                        HStack {
                            Text("")
                                .frame(width: 20)
                            Text(snippet.title)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textColor)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .padding(.leading, 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}
