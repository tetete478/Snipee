
//
//  FolderSidebar.swift
//  SnipeeMac
//

import SwiftUI

struct FolderSidebar: View {
    @Binding var personalFolders: [SnippetFolder]
    @Binding var masterFolders: [SnippetFolder]
    @Binding var selectedFolderId: String?
    @Binding var selectedSnippetId: String?
    @Binding var isShowingMaster: Bool
    var onSave: () -> Void
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("フォルダ")
                    .font(.headline)
                Spacer()
                Button(action: { isAddingFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .disabled(isShowingMaster)
            }
            .padding()
            
            Divider()
            
            // Segment Control
            Picker("", selection: $isShowingMaster) {
                Text("個別").tag(false)
                Text("マスタ").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Folder List
            List(selection: $selectedFolderId) {
                let folders = isShowingMaster ? masterFolders : personalFolders
                
                ForEach(folders) { folder in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        Text(folder.name)
                        Spacer()
                        Text("\(folder.snippets.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(folder.id)
                    .contextMenu {
                        if !isShowingMaster {
                            Button("名前を変更") {
                                renameFolder(folder)
                            }
                            Button("削除", role: .destructive) {
                                deleteFolder(folder)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Footer
            HStack {
                Text("\(isShowingMaster ? masterFolders.count : personalFolders.count) フォルダ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
        }
        .background(theme.backgroundColor)
        .sheet(isPresented: $isAddingFolder) {
            AddFolderSheet(
                folderName: $newFolderName,
                onAdd: addFolder,
                onCancel: { isAddingFolder = false }
            )
        }
    }
    
    private func addFolder() {
        guard !newFolderName.isEmpty else { return }
        let newFolder = SnippetFolder(name: newFolderName, order: personalFolders.count)
        personalFolders.append(newFolder)
        selectedFolderId = newFolder.id
        newFolderName = ""
        isAddingFolder = false
        onSave()
    }
    
    private func renameFolder(_ folder: SnippetFolder) {
        // TODO: Show rename dialog
    }
    
    private func deleteFolder(_ folder: SnippetFolder) {
        personalFolders.removeAll { $0.id == folder.id }
        if selectedFolderId == folder.id {
            selectedFolderId = personalFolders.first?.id
        }
        onSave()
    }
    
    private func moveFolder(from: IndexSet, to: Int) {
        personalFolders.move(fromOffsets: from, toOffset: to)
        onSave()
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
    }
}
