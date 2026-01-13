
//
//  AdminTab.swift
//  SnipeeMac
//

import SwiftUI
import UniformTypeIdentifiers

struct AdminTab: View {
    @State private var isAdmin = false
    @State private var selectedExportFolders: Set<String> = []
    @State private var folders: [SnippetFolder] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isAdmin {
                // Admin functions
                VStack(alignment: .leading, spacing: 12) {
                    Text("管理者機能")
                        .font(.headline)
                    
                    // Export
                    VStack(alignment: .leading, spacing: 8) {
                        Text("XMLエクスポート")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if folders.isEmpty {
                            Text("スニペットがありません")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(folders, id: \.id) { folder in
                                Toggle(folder.name, isOn: Binding(
                                    get: { selectedExportFolders.contains(folder.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedExportFolders.insert(folder.id)
                                        } else {
                                            selectedExportFolders.remove(folder.id)
                                        }
                                    }
                                ))
                            }
                        }
                        
                        Button(action: exportXML) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("エクスポート")
                            }
                        }
                        .disabled(selectedExportFolders.isEmpty)
                    }
                    
                    Divider()
                    
                    // Import
                    VStack(alignment: .leading, spacing: 8) {
                        Text("XMLインポート")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: importXML) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("ファイルを選択")
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Spreadsheet Link
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メンバー管理")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Link("📊 スプレッドシートを開く", destination: URL(string: "https://docs.google.com/spreadsheets")!)
                    }
                }
            } else {
                // Non-admin view
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("管理者権限が必要です")
                        .font(.headline)
                    
                    Text("この機能を使用するには、管理者としてログインしてください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        // TODO: Check admin status from MemberManager
        // For now, simulate admin access
        isAdmin = true
        folders = StorageService.shared.getPersonalSnippets() + StorageService.shared.getMasterSnippets()
    }
    
    private func exportXML() {
        let selectedFolders = folders.filter { selectedExportFolders.contains($0.id) }
        let xml = XMLParserHelper.export(folders: selectedFolders)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.xml]
        savePanel.nameFieldStringValue = "snippets.xml"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? xml.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func importXML() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.xml]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                if let data = try? Data(contentsOf: url) {
                    let parser = XMLParserHelper()
                    let importedFolders = parser.parse(data: data)
                    
                    var currentFolders = StorageService.shared.getPersonalSnippets()
                    currentFolders.append(contentsOf: importedFolders)
                    StorageService.shared.savePersonalSnippets(currentFolders)
                    
                    loadData()
                }
            }
        }
    }
}
