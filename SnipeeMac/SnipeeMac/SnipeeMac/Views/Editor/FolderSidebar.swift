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
    var onSave: () -> Void
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var expandedMasterFolderIds: Set<String> = []
    @State private var expandedPersonalFolderIds: Set<String> = []
    @State private var draggingSnippet: Snippet?
    @State private var draggingFolder: SnippetFolder?
    @State private var isMasterSectionExpanded: Bool = true
    @State private var isPersonalSectionExpanded: Bool = true
    
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
            
            // 階層式リスト（マスタ + 個別）
            ScrollView {
                LazyVStack(spacing: 0) {
                    // MARK: - マスタセクション
                    SectionHeader(
                        title: "マスタ",
                        count: masterFolders.count,
                        isExpanded: isMasterSectionExpanded,
                        onToggle: { isMasterSectionExpanded.toggle() }
                    )
                    
                    if isMasterSectionExpanded {
                        ForEach(masterFolders) { folder in
                            FolderRow(
                                folder: folder,
                                isExpanded: expandedMasterFolderIds.contains(folder.id),
                                selectedSnippetId: $selectedSnippetId,
                                isShowingMaster: true,
                                draggingSnippet: $draggingSnippet,
                                onToggle: { toggleMasterFolder(folder.id) },
                                onSelectSnippet: { snippet in
                                    isShowingMaster = true
                                    selectedFolderId = folder.id
                                    selectedSnippetId = snippet.id
                                },
                                onDeleteFolder: { },
                                onDeleteSnippet: { _ in },
                                onMoveSnippet: { from, to in
                                    moveMasterSnippet(in: folder, from: from, to: to)
                                }
                            )
                        }
                        
                        if masterFolders.isEmpty {
                            Text("マスタスニペットがありません")
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
                    
                    // MARK: - 個別セクション
                    SectionHeader(
                        title: "個別",
                        count: personalFolders.count,
                        isExpanded: isPersonalSectionExpanded,
                        onToggle: { isPersonalSectionExpanded.toggle() }
                    )
                    
                    if isPersonalSectionExpanded {
                        ForEach(personalFolders) { folder in
                            FolderRow(
                                folder: folder,
                                isExpanded: expandedPersonalFolderIds.contains(folder.id),
                                selectedSnippetId: $selectedSnippetId,
                                isShowingMaster: false,
                                draggingSnippet: $draggingSnippet,
                                onToggle: { togglePersonalFolder(folder.id) },
                                onSelectSnippet: { snippet in
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
                                }
                            )
                            .onDrag {
                                self.draggingFolder = folder
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
                }
                .padding(.vertical, 4)
            }
            .background(Color(.controlBackgroundColor))
            
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
    
    private func deleteSnippet(_ snippet: Snippet, from folder: SnippetFolder) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        personalFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        if selectedSnippetId == snippet.id {
            selectedSnippetId = personalFolders[folderIndex].snippets.first?.id
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
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Folder Row (階層式)

struct FolderRow: View {
    let folder: SnippetFolder
    let isExpanded: Bool
    @Binding var selectedSnippetId: String?
    let isShowingMaster: Bool
    @Binding var draggingSnippet: Snippet?
    let onToggle: () -> Void
    let onSelectSnippet: (Snippet) -> Void
    let onDeleteFolder: () -> Void
    let onDeleteSnippet: (Snippet) -> Void
    let onMoveSnippet: (IndexSet, Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // フォルダ行
            HStack(spacing: 6) {
                // インデント
                Color.clear.frame(width: 8)
                
                // 折りたたみ矢印
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(width: 12)
                
                Image(systemName: "folder.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                Text(folder.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.labelColor))
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(folder.snippets.count)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabelColor))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggle()
            }
            .contextMenu {
                if !isShowingMaster {
                    Button("削除", role: .destructive) {
                        onDeleteFolder()
                    }
                }
            }
            
            // スニペット一覧（展開時のみ）
            if isExpanded {
                ForEach(Array(folder.snippets.enumerated()), id: \.element.id) { index, snippet in
                    SnippetRow(
                        snippet: snippet,
                        isSelected: selectedSnippetId == snippet.id,
                        isShowingMaster: isShowingMaster,
                        onSelect: { onSelectSnippet(snippet) },
                        onDelete: { onDeleteSnippet(snippet) }
                    )
                    .onDrag {
                        self.draggingSnippet = snippet
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
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    let isSelected: Bool
    let isShowingMaster: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // インデント用スペース
            Color.clear.frame(width: 28)
            
            Image(systemName: "doc.text")
                .foregroundColor(Color(.secondaryLabelColor))
                .font(.system(size: 12))
            
            Text(snippet.title)
                .font(.system(size: 12))
                .foregroundColor(Color(.labelColor))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            if !isShowingMaster {
                Button("削除", role: .destructive) {
                    onDelete()
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
