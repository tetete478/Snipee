
//
//  ContentPanel.swift
//  SnipeeMac
//

import SwiftUI

struct ContentPanel: View {
    @Binding var folders: [SnippetFolder]
    @Binding var selectedFolderId: String?
    @Binding var selectedSnippetId: String?
    var isShowingMaster: Bool
    var onSave: () -> Void
    var onPromoteToMaster: ((Snippet, String) -> Void)?
    
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var isAddingSnippet = false
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var selectedFolder: SnippetFolder? {
        folders.first { $0.id == selectedFolderId }
    }
    
    var selectedSnippet: Snippet? {
        selectedFolder?.snippets.first { $0.id == selectedSnippetId }
    }
    
    var body: some View {
        HSplitView {
            // Snippet List
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(selectedFolder?.name ?? "スニペット")
                        .font(.headline)
                    Spacer()
                    if !isShowingMaster {
                        Button(action: { isAddingSnippet = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Divider()
                
                // List
                if let folder = selectedFolder {
                    List(selection: $selectedSnippetId) {
                        ForEach(folder.snippets) { snippet in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snippet.title)
                                    .fontWeight(.medium)
                                Text(snippet.content.prefix(50).description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .tag(snippet.id)
                            .padding(.vertical, 4)
                            .contextMenu {
                                if !isShowingMaster {
                                    let snippetToPromote = snippet
                                    Button {
                                        if let folderName = selectedFolder?.name {
                                            onPromoteToMaster?(snippetToPromote, folderName)
                                        }
                                    } label: {
                                        Label("マスタに昇格", systemImage: "arrow.up.circle")
                                    }
                                    
                                    Divider()
                                    
                                    let snippetToDelete = snippet
                                    Button("削除", role: .destructive) {
                                        deleteSnippet(snippetToDelete)
                                    }
                                }
                            }
                        }
                        .onMove { from, to in
                            if !isShowingMaster {
                                moveSnippet(from: from, to: to)
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                    Text("フォルダを選択してください")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Divider()
                
                // Footer
                HStack {
                    Text("\(selectedFolder?.snippets.count ?? 0) スニペット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 250)
            
            // Editor
            VStack(spacing: 0) {
                if selectedSnippet != nil {
                    // Title
                    HStack {
                        TextField("タイトル", text: $editingTitle)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .disabled(isShowingMaster)
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    // Content
                    TextEditor(text: $editingContent)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .disabled(isShowingMaster)
                    
                    Divider()
                    
                    // Footer
                    HStack {
                        Text("\(editingContent.count) 文字")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !isShowingMaster {
                            if let snippet = selectedSnippet, let folderName = selectedFolder?.name {
                                Button {
                                    onPromoteToMaster?(snippet, folderName)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.circle")
                                        Text("マスタに昇格")
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.orange)
                            }
                            
                            Button("保存") {
                                saveSnippet()
                            }
                            .disabled(editingTitle.isEmpty)
                        }
                    }
                    .padding(8)
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("スニペットを選択してください")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .frame(minWidth: 300)
        }
        .onChange(of: selectedSnippetId) { oldValue, newValue in
            loadSnippet()
        }
        .sheet(isPresented: $isAddingSnippet) {
            AddSnippetSheet(
                onAdd: addSnippet,
                onCancel: { isAddingSnippet = false }
            )
        }
    }
    
    private func loadSnippet() {
        if let snippet = selectedSnippet {
            editingTitle = snippet.title
            editingContent = snippet.content
        } else {
            editingTitle = ""
            editingContent = ""
        }
    }
    
    private func saveSnippet() {
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }),
              let snippetIndex = folders[folderIndex].snippets.firstIndex(where: { $0.id == selectedSnippetId }) else {
            return
        }
        
        folders[folderIndex].snippets[snippetIndex].title = editingTitle
        folders[folderIndex].snippets[snippetIndex].content = editingContent
        onSave()
    }
    
    private func addSnippet(title: String, content: String) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }) else {
            return
        }
        
        let newSnippet = Snippet(
            title: title,
            content: content,
            folder: folders[folderIndex].name,
            type: .personal,
            order: folders[folderIndex].snippets.count
        )
        
        folders[folderIndex].snippets.append(newSnippet)
        selectedSnippetId = newSnippet.id
        isAddingSnippet = false
        onSave()
    }
    
    private func deleteSnippet(_ snippet: Snippet) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }) else {
            return
        }
        
        folders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        selectedSnippetId = folders[folderIndex].snippets.first?.id
        onSave()
    }
    
    private func moveSnippet(from: IndexSet, to: Int) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }) else {
            return
        }
        
        folders[folderIndex].snippets.move(fromOffsets: from, toOffset: to)
        onSave()
    }
}

// MARK: - Add Snippet Sheet

struct AddSnippetSheet: View {
    var onAdd: (String, String) -> Void
    var onCancel: () -> Void
    
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("新しいスニペット")
                .font(.headline)
            
            TextField("タイトル", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $content)
                .frame(height: 150)
                .border(Color.gray.opacity(0.3))
            
            HStack {
                Button("キャンセル", action: onCancel)
                    .keyboardShortcut(.escape)
                
                Button("追加") {
                    onAdd(title, content)
                }
                .keyboardShortcut(.return)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
