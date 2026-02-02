//
//  FolderSidebar.swift
//  SnipeeMac
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderSidebar: View {
    @Binding var personalFolders: [SnippetFolder]
    @Binding var masterFolders: [SnippetFolder]
    @Binding var selectedFolderId: String?
    @Binding var selectedSnippetId: String?
    @Binding var isShowingMaster: Bool
    var isAdmin: Bool
    var isReadOnly: Bool = false
    var onSave: () -> Void
    var onPromoteSnippet: ((Snippet, String) -> Void)?
    var onDemoteSnippet: ((Snippet, String) -> Void)?
    var onPromoteFolder: ((SnippetFolder) -> Void)?
    var onDemoteFolder: ((SnippetFolder) -> Void)?
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var expandedMasterFolderIds: Set<String> = []
    @State private var expandedPersonalFolderIds: Set<String> = []
    @State private var draggingSnippet: Snippet?
    @State private var draggingSnippetSourceFolder: SnippetFolder?
    @State private var draggingSnippetIsMaster: Bool = false
    @State private var draggingFolder: SnippetFolder?
    @State private var draggingFolderIsMaster: Bool = false
    @State private var isMasterSectionExpanded: Bool = true
    @State private var isPersonalSectionExpanded: Bool = true
    
    
    
    // スニペット名インライン編集用（新規追加・名前変更共通）
    @State private var editingSnippetId: String?
    
    // フォルダ名インライン編集用
    @State private var editingFolderId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("スニペット")
                    .font(.headline)
                    .foregroundColor(Color(.labelColor))
                Spacer()
                Button(action: { isAddingFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(Color(.labelColor))
                }
                .buttonStyle(.plain)
                .help("個別フォルダを追加")
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // 階層式リスト（個別 + マスタ）
            ScrollView {
                LazyVStack(spacing: 0) {
                    // MARK: - 個別セクション
                    if !isReadOnly {
                        SectionHeader(
                            title: "個別",
                            count: personalFolders.count,
                            isExpanded: isPersonalSectionExpanded,
                            onToggle: { isPersonalSectionExpanded.toggle() }
                        )
                        .onDrop(of: [.text], delegate: SectionDropDelegate(
                            isMasterSection: false,
                            draggingSnippet: $draggingSnippet,
                            draggingSnippetSourceFolder: $draggingSnippetSourceFolder,
                            draggingSnippetIsMaster: $draggingSnippetIsMaster,
                            draggingFolder: $draggingFolder,
                            draggingFolderIsMaster: $draggingFolderIsMaster,
                            onPromoteSnippet: onPromoteSnippet,
                            onDemoteSnippet: onDemoteSnippet,
                            onPromoteFolder: onPromoteFolder,
                            onDemoteFolder: onDemoteFolder
                        ))
                        
                        if isPersonalSectionExpanded {
                            ForEach(personalFolders) { folder in
                                FolderRow(
                                    folder: folder,
                                    isExpanded: expandedPersonalFolderIds.contains(folder.id),
                                    selectedSnippetId: $selectedSnippetId,
                                    editingSnippetId: $editingSnippetId,
                                    editingFolderId: $editingFolderId,
                                    isShowingMaster: false,
                                    isAdmin: isAdmin,
                                    draggingSnippet: $draggingSnippet,
                                    onToggle: { togglePersonalFolder(folder.id) },
                                    onSelectSnippet: { snippet in
                                        editingSnippetId = nil
                                        editingFolderId = nil
                                        isShowingMaster = false
                                        selectedFolderId = folder.id
                                        selectedSnippetId = snippet.id
                                    },
                                    onDeleteFolder: { deleteFolder(folder) },
                                    onDeleteSnippet: { snippet in
                                        deleteSnippet(snippet, from: folder)
                                    },
                                    onMoveSnippet: { from, to in
                                        movePersonalSnippet(in: folder, from: from, to: to)
                                    },
                                    onRenameFolder: {
                                        editingFolderId = folder.id
                                    },
                                    onRenameSnippet: { snippet in
                                        editingSnippetId = snippet.id
                                    },
                                    onAddSnippet: {
                                        addSnippetInline(to: folder, isMaster: false)
                                    },
                                    onStartDragSnippet: { snippet in
                                        draggingSnippetSourceFolder = folder
                                        draggingSnippetIsMaster = false
                                    },
                                    onPromoteFolder: { onPromoteFolder?(folder) },
                                    onDemoteFolder: { },
                                    onPromoteSnippet: { snippet in onPromoteSnippet?(snippet, folder.name) },
                                    onDemoteSnippet: { _ in },
                                    onCommitSnippetRename: { snippetId, newTitle in
                                        commitSnippetRename(snippetId: snippetId, newTitle: newTitle, isMaster: false)
                                    },
                                    onCommitFolderRename: { newName in
                                        commitFolderRename(folderId: folder.id, newName: newName, isMaster: false)
                                    }
                                )
                                .onDrag {
                                    self.draggingFolder = folder
                                    self.draggingFolderIsMaster = false
                                    self.expandedPersonalFolderIds.removeAll()
                                    return NSItemProvider(object: folder.id as NSString)
                                }
                                .onDrop(of: [.text], delegate: FolderDropDelegate(
                                    folder: folder,
                                    folders: $personalFolders,
                                    draggingFolder: $draggingFolder,
                                    onSave: onSave
                                ))
                            }
                            
                            if personalFolders.isEmpty {
                                Text("個別スニペットがありません")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.tertiaryLabelColor))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // MARK: - セパレーター
                        Rectangle()
                            .fill(Color(.separatorColor))
                            .frame(height: 2)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                    }
                    
                    // MARK: - マスタセクション
                    SectionHeader(
                        title: "マスタ",
                        count: masterFolders.count,
                        isExpanded: isMasterSectionExpanded,
                        onToggle: { isMasterSectionExpanded.toggle() }
                    )
                    .onDrop(of: [.text], delegate: SectionDropDelegate(
                        isMasterSection: true,
                        draggingSnippet: $draggingSnippet,
                        draggingSnippetSourceFolder: $draggingSnippetSourceFolder,
                        draggingSnippetIsMaster: $draggingSnippetIsMaster,
                        draggingFolder: $draggingFolder,
                        draggingFolderIsMaster: $draggingFolderIsMaster,
                        onPromoteSnippet: onPromoteSnippet,
                        onDemoteSnippet: onDemoteSnippet,
                        onPromoteFolder: onPromoteFolder,
                        onDemoteFolder: onDemoteFolder
                    ))
                    
                    if isMasterSectionExpanded {
                        ForEach(masterFolders) { folder in
                            FolderRow(
                                folder: folder,
                                isExpanded: expandedMasterFolderIds.contains(folder.id),
                                selectedSnippetId: $selectedSnippetId,
                                editingSnippetId: $editingSnippetId,
                                editingFolderId: $editingFolderId,
                                isShowingMaster: true,
                                isAdmin: isAdmin,
                                isReadOnly: isReadOnly,
                                draggingSnippet: $draggingSnippet,
                                onToggle: { toggleMasterFolder(folder.id) },
                                onSelectSnippet: { snippet in
                                    editingSnippetId = nil
                                    editingFolderId = nil
                                    isShowingMaster = true
                                    selectedFolderId = folder.id
                                    selectedSnippetId = snippet.id
                                },
                                onDeleteFolder: { deleteMasterFolder(folder) },
                                onDeleteSnippet: { snippet in
                                    deleteMasterSnippet(snippet, from: folder)
                                },
                                onMoveSnippet: { from, to in
                                    moveMasterSnippet(in: folder, from: from, to: to)
                                },
                                onRenameFolder: {
                                    editingFolderId = folder.id
                                },
                                onRenameSnippet: { snippet in
                                    editingSnippetId = snippet.id
                                },
                                onAddSnippet: {
                                    addSnippetInline(to: folder, isMaster: true)
                                },
                                onStartDragSnippet: { snippet in
                                    draggingSnippetSourceFolder = folder
                                    draggingSnippetIsMaster = true
                                },
                                onPromoteFolder: { },
                                onDemoteFolder: { onDemoteFolder?(folder) },
                                onPromoteSnippet: { _ in },
                                onDemoteSnippet: { snippet in onDemoteSnippet?(snippet, folder.name) },
                                onCommitSnippetRename: { snippetId, newTitle in
                                    commitSnippetRename(snippetId: snippetId, newTitle: newTitle, isMaster: true)
                                },
                                onCommitFolderRename: { newName in
                                    commitFolderRename(folderId: folder.id, newName: newName, isMaster: true)
                                }
                            )
                            .onDrag {
                                guard !isReadOnly else { return NSItemProvider() }
                                self.draggingFolder = folder
                                self.draggingFolderIsMaster = true
                                return NSItemProvider(object: folder.id as NSString)
                            }
                            .onDrop(of: [.text], delegate: FolderDropDelegate(
                                folder: folder,
                                folders: $masterFolders,
                                draggingFolder: $draggingFolder,
                                onSave: onSave
                            ))
                        }
                        
                        if masterFolders.isEmpty {
                            Text("マスタスニペットがありません")
                                .font(.system(size: 11))
                                .foregroundColor(Color(.tertiaryLabelColor))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .background(Color(.controlBackgroundColor))
            .onTapGesture {
                // 背景クリックで編集を確定
                if editingFolderId != nil {
                    editingFolderId = nil
                }
                if editingSnippetId != nil {
                    editingSnippetId = nil
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(masterFolders.count + personalFolders.count) フォルダ")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.secondaryLabelColor))
                Spacer()
            }
            .padding(8)
            .background(Color(.windowBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
        // フォルダ追加シート
        .sheet(isPresented: $isAddingFolder) {
            AddFolderSheet(
                folderName: $newFolderName,
                onAdd: addFolder,
                onCancel: { isAddingFolder = false }
            )
        }
        
        .onAppear {
            // 最初のフォルダを展開
            if let firstMaster = masterFolders.first {
                expandedMasterFolderIds.insert(firstMaster.id)
            }
            if let firstPersonal = personalFolders.first {
                expandedPersonalFolderIds.insert(firstPersonal.id)
            }
        }
    }
    
    // MARK: - Toggle Functions
    
    private func toggleMasterFolder(_ folderId: String) {
        if expandedMasterFolderIds.contains(folderId) {
            expandedMasterFolderIds.remove(folderId)
        } else {
            expandedMasterFolderIds.insert(folderId)
        }
    }
    
    private func togglePersonalFolder(_ folderId: String) {
        if expandedPersonalFolderIds.contains(folderId) {
            expandedPersonalFolderIds.remove(folderId)
        } else {
            expandedPersonalFolderIds.insert(folderId)
        }
    }
    
    // MARK: - Folder Actions
    
    private func addFolder() {
        guard !newFolderName.isEmpty else { return }
        let newFolder = SnippetFolder(name: newFolderName, order: personalFolders.count)
        personalFolders.append(newFolder)
        selectedFolderId = newFolder.id
        isShowingMaster = false
        expandedPersonalFolderIds.insert(newFolder.id)
        newFolderName = ""
        isAddingFolder = false
        onSave()
    }
    
    private func deleteFolder(_ folder: SnippetFolder) {
        personalFolders.removeAll { $0.id == folder.id }
        expandedPersonalFolderIds.remove(folder.id)
        if selectedFolderId == folder.id {
            selectedFolderId = personalFolders.first?.id
            selectedSnippetId = personalFolders.first?.snippets.first?.id
            isShowingMaster = false
        }
        onSave()
    }
    
    private func deleteMasterFolder(_ folder: SnippetFolder) {
        guard isAdmin else { return }
        masterFolders.removeAll { $0.id == folder.id }
        expandedMasterFolderIds.remove(folder.id)
        if selectedFolderId == folder.id {
            selectedFolderId = masterFolders.first?.id
            selectedSnippetId = masterFolders.first?.snippets.first?.id
        }
        onSave()
    }
    
    private func deleteSnippet(_ snippet: Snippet, from folder: SnippetFolder) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        personalFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        if selectedSnippetId == snippet.id {
            selectedSnippetId = personalFolders[folderIndex].snippets.first?.id
        }
        onSave()
    }
    
    private func deleteMasterSnippet(_ snippet: Snippet, from folder: SnippetFolder) {
        guard isAdmin else { return }
        guard let folderIndex = masterFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        masterFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        if selectedSnippetId == snippet.id {
            selectedSnippetId = masterFolders[folderIndex].snippets.first?.id
        }
        onSave()
    }
    
    // MARK: - Rename Actions
    
    private func commitFolderRename(folderId: String, newName: String, isMaster: Bool) {
        editingFolderId = nil
        
        // 空または空白のみの場合は変更をキャンセル
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if isMaster {
            if let index = masterFolders.firstIndex(where: { $0.id == folderId }) {
                // 同じ名前なら保存しない
                guard masterFolders[index].name != newName else { return }
                masterFolders[index].name = newName
            }
        } else {
            if let index = personalFolders.firstIndex(where: { $0.id == folderId }) {
                guard personalFolders[index].name != newName else { return }
                personalFolders[index].name = newName
            }
        }
        
        onSave()
    }
    
    // MARK: - Add Snippet Inline
    
    private func addSnippetInline(to folder: SnippetFolder, isMaster: Bool) {
        let newSnippet = Snippet(
            title: "新規スニペット",
            content: "",
            folder: folder.name,
            type: isMaster ? .master : .personal,
            order: folder.snippets.count
        )
        
        if isMaster {
            if let index = masterFolders.firstIndex(where: { $0.id == folder.id }) {
                masterFolders[index].snippets.append(newSnippet)
                expandedMasterFolderIds.insert(folder.id)
                selectedSnippetId = newSnippet.id
                selectedFolderId = folder.id
                isShowingMaster = true
                editingSnippetId = newSnippet.id
            }
        } else {
            if let index = personalFolders.firstIndex(where: { $0.id == folder.id }) {
                personalFolders[index].snippets.append(newSnippet)
                expandedPersonalFolderIds.insert(folder.id)
                selectedSnippetId = newSnippet.id
                selectedFolderId = folder.id
                isShowingMaster = false
                editingSnippetId = newSnippet.id
            }
        }
    }
    
    private func commitSnippetRename(snippetId: String, newTitle: String, isMaster: Bool) {
        editingSnippetId = nil
        
        // 空または空白のみの場合は変更をキャンセル
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        
        if isMaster {
            for folderIndex in masterFolders.indices {
                if let snippetIndex = masterFolders[folderIndex].snippets.firstIndex(where: { $0.id == snippetId }) {
                    // 同じ名前なら保存しない
                    guard masterFolders[folderIndex].snippets[snippetIndex].title != newTitle else { return }
                    masterFolders[folderIndex].snippets[snippetIndex].title = newTitle
                    break
                }
            }
        } else {
            for folderIndex in personalFolders.indices {
                if let snippetIndex = personalFolders[folderIndex].snippets.firstIndex(where: { $0.id == snippetId }) {
                    guard personalFolders[folderIndex].snippets[snippetIndex].title != newTitle else { return }
                    personalFolders[folderIndex].snippets[snippetIndex].title = newTitle
                    break
                }
            }
        }
        
        onSave()
    }
    
    // MARK: - Move Snippets
    
    private func moveMasterSnippet(in folder: SnippetFolder, from: IndexSet, to: Int) {
        guard let folderIndex = masterFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        masterFolders[folderIndex].snippets.move(fromOffsets: from, toOffset: to)
        onSave()
    }
    
    private func movePersonalSnippet(in folder: SnippetFolder, from: IndexSet, to: Int) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        personalFolders[folderIndex].snippets.move(fromOffsets: from, toOffset: to)
        onSave()
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(.secondaryLabelColor))
                .frame(width: 12)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.secondaryLabelColor))
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundColor(Color(.tertiaryLabelColor))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.separatorColor).opacity(0.5))
                .cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Section Drop Delegate (昇格/降格用)

struct SectionDropDelegate: DropDelegate {
    let isMasterSection: Bool
    @Binding var draggingSnippet: Snippet?
    @Binding var draggingSnippetSourceFolder: SnippetFolder?
    @Binding var draggingSnippetIsMaster: Bool
    @Binding var draggingFolder: SnippetFolder?
    @Binding var draggingFolderIsMaster: Bool
    var onPromoteSnippet: ((Snippet, String) -> Void)?
    var onDemoteSnippet: ((Snippet, String) -> Void)?
    var onPromoteFolder: ((SnippetFolder) -> Void)?
    var onDemoteFolder: ((SnippetFolder) -> Void)?
    
    func performDrop(info: DropInfo) -> Bool {
        // スニペットのドロップ
        if let snippet = draggingSnippet, let folder = draggingSnippetSourceFolder {
            if isMasterSection && !draggingSnippetIsMaster {
                // 個別 → マスタ（昇格）
                onPromoteSnippet?(snippet, folder.name)
            } else if !isMasterSection && draggingSnippetIsMaster {
                // マスタ → 個別（降格）
                onDemoteSnippet?(snippet, folder.name)
            }
        }
        
        // フォルダのドロップ
        if let folder = draggingFolder {
            if isMasterSection && !draggingFolderIsMaster {
                // 個別 → マスタ（昇格）
                onPromoteFolder?(folder)
            } else if !isMasterSection && draggingFolderIsMaster {
                // マスタ → 個別（降格）
                onDemoteFolder?(folder)
            }
        }
        
        draggingSnippet = nil
        draggingSnippetSourceFolder = nil
        draggingFolder = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // ドロップエリアに入った
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return draggingSnippet != nil || draggingFolder != nil
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Folder Drop Delegate

struct FolderDropDelegate: DropDelegate {
    let folder: SnippetFolder
    @Binding var folders: [SnippetFolder]
    @Binding var draggingFolder: SnippetFolder?
    let onSave: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggingFolder = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragging = draggingFolder,
              dragging.id != folder.id,
              let fromIndex = folders.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = folders.firstIndex(where: { $0.id == folder.id }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            folders.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
        onSave()
    }
    
    }

// MARK: - Folder Row (階層式)

struct FolderRow: View {
    let folder: SnippetFolder
    let isExpanded: Bool
    @Binding var selectedSnippetId: String?
    @Binding var editingSnippetId: String?
    @Binding var editingFolderId: String?
    let isShowingMaster: Bool
    let isAdmin: Bool
    var isReadOnly: Bool = false
    @Binding var draggingSnippet: Snippet?
    let onToggle: () -> Void
    let onSelectSnippet: (Snippet) -> Void
    let onDeleteFolder: () -> Void
    let onDeleteSnippet: (Snippet) -> Void
    let onMoveSnippet: (IndexSet, Int) -> Void
    let onRenameFolder: () -> Void
    let onRenameSnippet: (Snippet) -> Void
    let onAddSnippet: () -> Void
    let onStartDragSnippet: (Snippet) -> Void
    let onPromoteFolder: () -> Void
    let onDemoteFolder: () -> Void
    let onPromoteSnippet: (Snippet) -> Void
    let onDemoteSnippet: (Snippet) -> Void
    let onCommitSnippetRename: ((String, String) -> Void)?
    let onCommitFolderRename: ((String) -> Void)?
    
    @State private var editingFolderName: String = ""
    @FocusState private var isFolderNameFocused: Bool
    
    private var isEditingFolder: Bool {
        editingFolderId == folder.id
    }
    
    private var canEdit: Bool {
        !isReadOnly && (!isShowingMaster || isAdmin)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // フォルダ行
            HStack(spacing: 6) {
                // インデント
                Color.clear.frame(width: 8)
                
                // 折りたたみ矢印 + フォルダアイコン（クリックでトグル）
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabelColor))
                        .frame(width: 12)
                    
                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggle()
                }
                
                // フォルダ名（インライン編集対応）
                if isEditingFolder {
                    TextField("フォルダ名", text: $editingFolderName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                        .focused($isFolderNameFocused)
                        .onSubmit {
                            onCommitFolderRename?(editingFolderName)
                        }
                        .onAppear {
                            editingFolderName = folder.name
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFolderNameFocused = true
                            }
                        }
                        .onChange(of: isFolderNameFocused) { _, focused in
                            if !focused && isEditingFolder {
                                onCommitFolderRename?(editingFolderName)
                            }
                        }
                } else {
                    Text(folder.name)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.labelColor))
                        .lineLimit(1)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if canEdit {
                                onRenameFolder()
                            }
                        }
                        .onTapGesture(count: 1) {
                            onToggle()
                        }
                }
                
                Spacer()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isEditingFolder {
                            onToggle()
                        }
                    }
                
                Text("\(folder.snippets.count)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabelColor))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .contextMenu {
                if canEdit {
                    Button {
                        onAddSnippet()
                    } label: {
                        Label("新規スニペット追加", systemImage: "doc.badge.plus")
                    }
                    
                    Button {
                        onRenameFolder()
                    } label: {
                        Label("名前を変更", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    if isAdmin {
                        if isShowingMaster {
                            Button {
                                onDemoteFolder()
                            } label: {
                                Label("個別に降格", systemImage: "arrow.down.circle")
                            }
                        } else {
                            Button {
                                onPromoteFolder()
                            } label: {
                                Label("マスタに昇格", systemImage: "arrow.up.circle")
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDeleteFolder()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
            
            // スニペット一覧（展開時のみ）
            if isExpanded {
                ForEach(Array(folder.snippets.enumerated()), id: \.element.id) { index, snippet in
                    SnippetRow(
                        snippet: snippet,
                        isSelected: selectedSnippetId == snippet.id,
                        isEditing: editingSnippetId == snippet.id,
                        isShowingMaster: isShowingMaster,
                        isAdmin: isAdmin,
                        isReadOnly: isReadOnly,
                        onSelect: { onSelectSnippet(snippet) },
                        onDelete: { onDeleteSnippet(snippet) },
                        onRename: { onRenameSnippet(snippet) },
                        onAddSnippet: onAddSnippet,
                        onPromoteSnippet: { onPromoteSnippet(snippet) },
                        onDemoteSnippet: { onDemoteSnippet(snippet) },
                        onCommitRename: { newTitle in
                            onCommitSnippetRename?(snippet.id, newTitle)
                        }
                    )
                    .onDrag {
                        guard canEdit else { return NSItemProvider() }
                        self.draggingSnippet = snippet
                        onStartDragSnippet(snippet)
                        return NSItemProvider(object: snippet.id as NSString)
                    }
                    .onDrop(of: [.text], delegate: SnippetDropDelegate(
                        snippet: snippet,
                        snippets: folder.snippets,
                        draggingSnippet: $draggingSnippet,
                        onMove: onMoveSnippet
                    ))
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Snippet Drop Delegate

struct SnippetDropDelegate: DropDelegate {
    let snippet: Snippet
    let snippets: [Snippet]
    @Binding var draggingSnippet: Snippet?
    let onMove: (IndexSet, Int) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggingSnippet = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragging = draggingSnippet,
              dragging.id != snippet.id,
              let fromIndex = snippets.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = snippets.firstIndex(where: { $0.id == snippet.id }) else {
            return
        }
        
        onMove(IndexSet(integer: fromIndex), toIndex > fromIndex ? toIndex + 1 : toIndex)
    }
    
    }

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    let isSelected: Bool
    let isEditing: Bool
    let isShowingMaster: Bool
    let isAdmin: Bool
    var isReadOnly: Bool = false
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onAddSnippet: () -> Void
    let onPromoteSnippet: () -> Void
    let onDemoteSnippet: () -> Void
    let onCommitRename: ((String) -> Void)?
    
    @State private var editingTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private var canEdit: Bool {
        !isReadOnly && (!isShowingMaster || isAdmin)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: 28)
            
            Image(systemName: "doc.text")
                .foregroundColor(Color(.secondaryLabelColor))
                .font(.system(size: 12))
            
            if isEditing {
                TextField("タイトル", text: $editingTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        onCommitRename?(editingTitle)
                    }
                    .onAppear {
                        editingTitle = snippet.title
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                    .onChange(of: isTextFieldFocused) { _, focused in
                        if !focused && isEditing {
                            onCommitRename?(editingTitle)
                        }
                    }
            } else {
                Text(snippet.title)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.labelColor))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected || isEditing ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isEditing && canEdit {
                onRename()
            }
        }
        .onTapGesture(count: 1) {
            if !isEditing {
                onSelect()
            }
        }
        .contextMenu {
            if canEdit {
                Button {
                    onAddSnippet()
                } label: {
                    Label("新規スニペット追加", systemImage: "doc.badge.plus")
                }
                
                Button {
                    onRename()
                } label: {
                    Label("名前を変更", systemImage: "pencil")
                }
                
                Divider()
                
                if isAdmin {
                    if isShowingMaster {
                        Button {
                            onDemoteSnippet()
                        } label: {
                            Label("個別に降格", systemImage: "arrow.down.circle")
                        }
                    } else {
                        Button {
                            onPromoteSnippet()
                        } label: {
                            Label("マスタに昇格", systemImage: "arrow.up.circle")
                        }
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Add Folder Sheet

struct AddFolderSheet: View {
    @Binding var folderName: String
    var onAdd: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("新しいフォルダ")
                .font(.headline)
                .foregroundColor(Color(.labelColor))
            
            TextField("フォルダ名", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            
            HStack {
                Button("キャンセル", action: onCancel)
                    .keyboardShortcut(.escape)
                
                Button("追加", action: onAdd)
                    .keyboardShortcut(.return)
                    .disabled(folderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .background(Color(.windowBackgroundColor))
    }
}

