
//
//  SnippetEditorView.swift
//  SnipeeMac
//

import SwiftUI

struct SnippetEditorView: View {
    @State private var personalFolders: [SnippetFolder] = []
    @State private var masterFolders: [SnippetFolder] = []
    @State private var selectedFolderId: String? = nil
    @State private var selectedSnippetId: String? = nil
    @State private var isShowingMaster: Bool = false
    
    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var body: some View {
        HSplitView {
            // Left: Folder Sidebar
            FolderSidebar(
                personalFolders: $personalFolders,
                masterFolders: $masterFolders,
                selectedFolderId: $selectedFolderId,
                selectedSnippetId: $selectedSnippetId,
                isShowingMaster: $isShowingMaster,
                onSave: saveData
            )
            .frame(minWidth: 200, maxWidth: 300)
            
            // Right: Content Panel
            ContentPanel(
                folders: isShowingMaster ? $masterFolders : $personalFolders,
                selectedFolderId: $selectedFolderId,
                selectedSnippetId: $selectedSnippetId,
                isShowingMaster: isShowingMaster,
                onSave: saveData
            )
            .frame(minWidth: 400)
        }
        .frame(minWidth: 700, minHeight: 400)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        personalFolders = StorageService.shared.getPersonalSnippets()
        masterFolders = StorageService.shared.getMasterSnippets()
        
        // Select first folder if available
        if let firstFolder = personalFolders.first {
            selectedFolderId = firstFolder.id
        }
    }
    
    private func saveData() {
        StorageService.shared.savePersonalSnippets(personalFolders)
        StorageService.shared.saveMasterSnippets(masterFolders)
    }
}
