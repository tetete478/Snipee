//
//  AdminTab.swift
//  SnipeeMac
//

import SwiftUI
import UniformTypeIdentifiers

struct AdminTab: View {
    @State private var isAdmin = false
    @State private var userDepartment = ""
    @State private var selectedExportFolders: Set<String> = []
    @State private var folders: [SnippetFolder] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var uploadSuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isAdmin {
                VStack(alignment: .leading, spacing: 12) {
                    Text("管理者機能")
                        .font(.headline)
                    
                    // Upload Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("マスタXMLアップロード")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("現在のマスタスニペットをDriveにアップロードします")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button(action: uploadMasterXML) {
                                HStack {
                                    if isUploading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "icloud.and.arrow.up")
                                    }
                                    Text(isUploading ? "アップロード中..." : "マスタをアップロード")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isUploading || userDepartment.isEmpty)
                            
                            Spacer()
                        }
                        
                        if let error = uploadError {
                            Text("エラー: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if uploadSuccess {
                            Text("✅ アップロード完了")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    // Export Section
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
                    
                    // Import Section
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
                        
                        Link("📊 スプレッドシートを開く", destination: URL(string: "https://docs.google.com/spreadsheets/d/1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM")!)
                    }
                }
            } else {
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
        let cached = SyncService.shared.getCachedMemberInfo()
        if let role = cached.role {
            isAdmin = (role == "管理者" || role == "最高管理者")
        }
        if let dept = cached.department {
            userDepartment = dept
        }
        folders = StorageService.shared.getPersonalSnippets() + StorageService.shared.getMasterSnippets()
    }
    
    private func uploadMasterXML() {
        isUploading = true
        uploadError = nil
        uploadSuccess = false
        
        GoogleSheetsService.shared.fetchDepartmentFileId(department: userDepartment) { result in
            switch result {
            case .success(let fileId):
                let masterFolders = StorageService.shared.getMasterSnippets()
                let xmlString = XMLParserHelper.export(folders: masterFolders)
                guard let xmlData = xmlString.data(using: .utf8) else {
                    isUploading = false
                    uploadError = "XML変換に失敗しました"
                    return
                }
                
                GoogleDriveService.shared.uploadXMLFile(fileId: fileId, xmlData: xmlData) { uploadResult in
                    isUploading = false
                    switch uploadResult {
                    case .success:
                        uploadSuccess = true
                    case .failure(let error):
                        uploadError = error.localizedDescription
                    }
                }
                
            case .failure(let error):
                isUploading = false
                uploadError = error.localizedDescription
            }
        }
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
