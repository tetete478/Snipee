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
    var isReadOnly: Bool = false
    var isAdmin: Bool = false
    var onSave: () -> Void
    var onAddSnippet: (() -> Void)?
    @Binding var saveRequestId: Int
    
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var editingDescription = ""
    @State private var isDescriptionVisible = true
    @State private var isEditingTitle = false
    @State private var saveState: SaveState = .none
    @State private var saveTask: Task<Void, Never>?
    @State private var hasUnsavedChanges = false
    @State private var snippetIndex: [String: Snippet] = [:]
    @FocusState private var isTitleFieldFocused: Bool
    
    enum SaveState {
        case none
        case saving
        case saved
    }
    
    var selectedFolder: SnippetFolder? {
        folders.first { $0.id == selectedFolderId }
    }
    
    var selectedSnippet: Snippet? {
        guard let snippetId = selectedSnippetId else { return nil }
        return selectedFolder?.snippets.first { $0.id == snippetId }
    }
    
    private var isEditable: Bool {
        !isReadOnly && (!isShowingMaster || isAdmin)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            
            Divider()
            
            if selectedSnippet != nil {
                titleSection
                
                Divider()
                
                contentSection
                
                Divider()
                
                editorFooter
            } else {
                emptyState
            }
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            loadSnippet()
        }
        .onChange(of: selectedSnippetId) { oldValue, newValue in
            loadSnippet()
        }
        .onChange(of: selectedFolderId) { oldValue, newValue in
            loadSnippet()
        }
        .onChange(of: folders.count) { oldValue, newValue in
            loadSnippet()
        }
        .onChange(of: selectedSnippet?.title) { _, newTitle in
            if let newTitle, !isEditingTitle, editingTitle != newTitle {
                editingTitle = newTitle
            }
        }
        .onChange(of: editingContent) { oldValue, newValue in
            if oldValue != newValue && newValue != selectedSnippet?.content {
                hasUnsavedChanges = true
                autoSave()
            }
        }
        .onChange(of: editingDescription) { oldValue, newValue in
            if oldValue != newValue && newValue != (selectedSnippet?.description ?? "") {
                hasUnsavedChanges = true
                autoSave()
            }
        }
        .onDisappear {
            if hasUnsavedChanges {
                saveImmediately()
            }
        }
        .onChange(of: saveRequestId) { _, _ in
            if hasUnsavedChanges {
                saveImmediately()
            }
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
            
            if isReadOnly {
                Text("(参照モード)")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            if isEditable {
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
            if isEditingTitle {
                TextField("タイトル", text: $editingTitle)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .foregroundColor(Color(.labelColor))
                    .focused($isTitleFieldFocused)
                    .onSubmit {
                        commitTitleEdit()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTitleFieldFocused = true
                        }
                    }
                    .onChange(of: isTitleFieldFocused) { _, focused in
                        if !focused {
                            commitTitleEdit()
                        }
                    }
            } else {
                Text(editingTitle.isEmpty ? "タイトル" : editingTitle)
                    .font(.title2)
                    .foregroundColor(editingTitle.isEmpty ? Color(.placeholderTextColor) : Color(.labelColor))
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        if isEditable {
                            isEditingTitle = true
                        }
                    }
            }
            
            Spacer()
            
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
            if isReadOnly {
                ScrollView {
                    Text(editingContent)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .background(Color(.textBackgroundColor))
            } else {
                TextEditor(text: $editingContent)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.textBackgroundColor))
                    .disabled(!isEditable)
            }
            
            if isDescriptionVisible && !isReadOnly {
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
                        .disabled(!isEditable)
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
            
            if isEditable {
                switch saveState {
                case .none:
                    EmptyView()
                case .saving:
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("保存中...")
                            .font(.system(size: 11))
                            .foregroundColor(Color(.secondaryLabelColor))
                    }
                case .saved:
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("保存完了")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: saveState)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabelColor))
            
            Text(isReadOnly ? "スニペットを選択して参照" : "スニペットを選択してください")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabelColor))
            
            if isEditable {
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
        // 切り替え前に変更があれば保存
        if hasUnsavedChanges {
            saveImmediately()
        }
        
        // スニペットインデックス再構築
        if let folder = selectedFolder {
            snippetIndex = Dictionary(uniqueKeysWithValues: folder.snippets.map { ($0.id, $0) })
        } else {
            snippetIndex = [:]
        }
        
        isEditingTitle = false
        hasUnsavedChanges = false
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
    
    private func commitTitleEdit() {
        isEditingTitle = false
        if editingTitle.isEmpty {
            editingTitle = "新規スニペット"
        }
        saveSnippet()
    }
    
    private func saveSnippet() {
        guard !isReadOnly else {
            return
        }
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }),
              let snippetIndex = folders[folderIndex].snippets.firstIndex(where: { $0.id == selectedSnippetId }) else {
            return
        }

        folders[folderIndex].snippets[snippetIndex].title = editingTitle
        folders[folderIndex].snippets[snippetIndex].content = editingContent
        folders[folderIndex].snippets[snippetIndex].description = editingDescription.isEmpty ? nil : editingDescription

        hasUnsavedChanges = false
        onSave()
    }
    
    private func autoSave() {
        guard !isReadOnly && isEditable else {
            return
        }
        guard folders.firstIndex(where: { $0.id == selectedFolderId }) != nil else {
            return
        }

        // 既存のタスクをキャンセル
        saveTask?.cancel()

        // キャプチャ時点のIDと内容を記録
        let capturedFolderId = selectedFolderId
        let capturedSnippetId = selectedSnippetId
        let capturedContent = editingContent
        let capturedDescription = editingDescription

        // 0.5秒後に保存
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                saveState = .saving
            }

            // 少し待ってから保存（UIに反映）
            try? await Task.sleep(nanoseconds: 200_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let folderIndex = folders.firstIndex(where: { $0.id == capturedFolderId }),
                      let snippetIndex = folders[folderIndex].snippets.firstIndex(where: { $0.id == capturedSnippetId }) else {
                    saveState = .none
                    return
                }

                folders[folderIndex].snippets[snippetIndex].content = capturedContent
                folders[folderIndex].snippets[snippetIndex].description = capturedDescription.isEmpty ? nil : capturedDescription

                hasUnsavedChanges = false
                onSave()

                saveState = .saved

                // 2秒後に非表示
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        if saveState == .saved {
                            saveState = .none
                        }
                    }
                }
            }
        }
    }
    
    private func saveImmediately() {
        // 保留中のタスクをキャンセル
        saveTask?.cancel()
        saveState = .none

        guard !isReadOnly && isEditable else {
            return
        }
        guard let folderIndex = folders.firstIndex(where: { $0.id == selectedFolderId }),
              let snippetIndex = folders[folderIndex].snippets.firstIndex(where: { $0.id == selectedSnippetId }) else {
            return
        }

        folders[folderIndex].snippets[snippetIndex].content = editingContent
        folders[folderIndex].snippets[snippetIndex].description = editingDescription.isEmpty ? nil : editingDescription

        hasUnsavedChanges = false
        onSave()
    }
}
