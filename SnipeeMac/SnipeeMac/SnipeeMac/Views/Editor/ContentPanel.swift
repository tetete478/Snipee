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
    var onAddSnippet: (() -> Void)?
    
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var editingDescription = ""
    @State private var isDescriptionVisible = true
    
    var selectedFolder: SnippetFolder? {
        folders.first { $0.id == selectedFolderId }
    }
    
    var selectedSnippet: Snippet? {
        selectedFolder?.snippets.first { $0.id == selectedSnippetId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedSnippet != nil {
                // ツールバー
                editorToolbar
                
                Divider()
                
                // タイトル
                titleSection
                
                Divider()
                
                // コンテンツ + 説明
                contentSection
                
                Divider()
                
                // フッター
                editorFooter
            } else {
                emptyState
            }
        }
        .background(Color(.windowBackgroundColor))
        .onChange(of: selectedSnippetId) { oldValue, newValue in
            loadSnippet()
        }
    }
    
    // MARK: - Editor Toolbar
    
    private var editorToolbar: some View {
        HStack {
            if let folder = selectedFolder {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text(folder.name)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabelColor))
                }
            }
            
            Spacer()
            
            if !isShowingMaster {
                Button(action: { onAddSnippet?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("新規スニペット")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        HStack {
            TextField("タイトル", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.title2)
                .foregroundColor(Color(.labelColor))
                .disabled(isShowingMaster)
            
            Spacer()
            
            // 説明トグルボタン
            Button(action: { isDescriptionVisible.toggle() }) {
                Image(systemName: isDescriptionVisible ? "sidebar.right" : "sidebar.left")
                    .foregroundColor(Color(.secondaryLabelColor))
            }
            .buttonStyle(.plain)
            .help(isDescriptionVisible ? "説明を隠す" : "説明を表示")
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        HStack(spacing: 0) {
            // メインコンテンツ
            TextEditor(text: $editingContent)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.textBackgroundColor))
                .disabled(isShowingMaster)
            
            // 説明パネル
            if isDescriptionVisible {
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("説明")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabelColor))
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    TextEditor(text: $editingDescription)
                        .font(.system(size: 12))
                        .padding(4)
                        .scrollContentBackground(.hidden)
                        .background(Color(.textBackgroundColor))
                        .disabled(isShowingMaster)
                }
                .frame(width: 200)
                .background(Color(.controlBackgroundColor))
            }
        }
    }
    
    // MARK: - Editor Footer
    
    private var editorFooter: some View {
        HStack {
            Text("\(editingContent.count) 文字")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
            
            Spacer()
            
            if !isShowingMaster {
                // マスタに昇格ボタン
                if let snippet = selectedSnippet, let folderName = selectedFolder?.name {
                    Button {
                        onPromoteToMaster?(snippet, folderName)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle")
                            Text("マスタに昇格")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                }
                
                // 保存ボタン
                Button("保存") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(editingTitle.isEmpty)
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabelColor))
            
            Text("スニペットを選択してください")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabelColor))
            
            if !isShowingMaster {
                Button(action: { onAddSnippet?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("新規スニペット作成")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func loadSnippet() {
        if let snippet = selectedSnippet {
            editingTitle = snippet.title
            editingContent = snippet.content
            editingDescription = snippet.description ?? ""
        } else {
            editingTitle = ""
            editingContent = ""
            editingDescription = ""
        }
    }
    
    private func saveSnippet() {
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }),
              let snippetIndex = folders[folderIndex].snippets.firstIndex(where: { $0.id == selectedSnippetId }) else {
            return
        }
        
        folders[folderIndex].snippets[snippetIndex].title = editingTitle
        folders[folderIndex].snippets[snippetIndex].content = editingContent
        folders[folderIndex].snippets[snippetIndex].description = editingDescription.isEmpty ? nil : editingDescription
        onSave()
    }
}
