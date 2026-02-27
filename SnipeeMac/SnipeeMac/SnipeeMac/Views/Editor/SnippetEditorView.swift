//
//  SnippetEditorView.swift
//  SnipeeMac
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SnippetEditorView: View {
    @State private var personalFolders: [SnippetFolder] = []
    @State private var masterFolders: [SnippetFolder] = []
    @State private var selectedFolderId: String? = nil
    @State private var selectedSnippetId: String? = nil
    @State private var isShowingMaster: Bool = false
    @State private var isImporting: Bool = false
    @State private var isAddingSnippet: Bool = false
    @State private var isExporting: Bool = false
    @State private var importTarget: ImportExportTarget? = nil
    @State private var exportTarget: ImportExportTarget? = nil
    @State private var isUploading: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    @State private var isAdmin: Bool = false
    @State private var userDepartment: String = ""
    @State private var saveRequestId: Int = 0
    
    // Export Sheet States
    @State private var isShowingExportSheet: Bool = false
    @State private var exportSheetType: ImportExportTarget? = nil
    @State private var selectedExportFolders: Set<String> = []
    @State private var exportFormat: ExportFormat = .snipee

    private let theme: ColorTheme = .silver
    
    enum ImportExportTarget {
        case personal
        case master
    }
    
    enum ExportFormat {
        case snipee
        case clipy
    }
    
    var body: some View {
        mainContent
            .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            loadData()
            loadAdminStatus()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.xml],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        
        .alert("通知", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $isAddingSnippet) {
            AddSnippetSheet(
                onAdd: addSnippet,
                onCancel: { isAddingSnippet = false }
            )
        }
        .sheet(isPresented: $isShowingExportSheet) {
            ExportSheet(
                selectedType: $exportSheetType,
                selectedFolders: $selectedExportFolders,
                exportFormat: $exportFormat,
                personalFolders: personalFolders,
                masterFolders: masterFolders,
                isAdmin: isAdmin,
                onExport: { selectedFolders in
                    performExport(selectedFolders: selectedFolders, selectedType: $exportSheetType.wrappedValue)
                },
                onCancel: { isShowingExportSheet = false }
            )
        }
    }

    
    // MARK: - Main Content
    
    private var mainContent: some View {
        HSplitView {
            sidebarView
            
            VStack(spacing: 0) {
                editorToolbar
                Divider()
                contentPanelView
            }
        }
    }
    
    private var sidebarView: some View {
        FolderSidebar(
            personalFolders: $personalFolders,
            masterFolders: currentMasterFolders,
            selectedFolderId: $selectedFolderId,
            selectedSnippetId: $selectedSnippetId,
            isShowingMaster: $isShowingMaster,
            isAdmin: isAdmin,
            isReadOnly: false,
            onSave: saveData,
            onPromoteSnippet: promoteSnippetToMaster,
            onDemoteSnippet: demoteSnippetToPersonal,
            onPromoteFolder: promoteFolderToMaster,
            onDemoteFolder: demoteFolderToPersonal
        )
        .frame(minWidth: 200, maxWidth: 280)
    }
    
    private var currentMasterFolders: Binding<[SnippetFolder]> {
        $masterFolders
    }
    
    private var currentContentFolders: Binding<[SnippetFolder]> {
        if isShowingMaster {
            return $masterFolders
        } else {
            return $personalFolders
        }
    }
    
    private var contentPanelView: some View {
        ContentPanel(
            folders: currentContentFolders,
            selectedFolderId: $selectedFolderId,
            selectedSnippetId: $selectedSnippetId,
            isShowingMaster: isShowingMaster,
            isReadOnly: false,
            isAdmin: isAdmin,
            onSave: { saveData() },
            onAddSnippet: { isAddingSnippet = true },
            saveRequestId: $saveRequestId
        )
        .frame(minWidth: 400)
    }
    
    // MARK: - Editor Toolbar
    
    private var editorToolbar: some View {
        HStack {
            Spacer()
            
            Button(action: { syncSnippets() }) {
                Label("同期", systemImage: "arrow.triangle.2.circlepath")
            }
            
            importMenu
            
            Button(action: { isShowingExportSheet = true }) {
                Label("エクスポート", systemImage: "square.and.arrow.up")
            }
            .disabled(personalFolders.isEmpty && masterFolders.isEmpty)
            
            if isAdmin {
            
            Button(action: uploadMasterSnippets) {
                Label("マスタ更新", systemImage: "icloud.and.arrow.up")
            }
        }
            
            if isUploading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }
    
    private var importMenu: some View {
        Menu {
            Button("個別スニペット") {
                importTarget = .personal
                isImporting = true
            }
            if isAdmin {
                Button("マスタスニペット") {
                    importTarget = .master
                    isImporting = true
                }
            }
        } label: {
            Label("インポート", systemImage: "square.and.arrow.down")
        }
        .help("XMLファイルを読み込む")
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        personalFolders = StorageService.shared.getPersonalSnippets()
        masterFolders = StorageService.shared.getMasterSnippets()

        if let firstFolder = personalFolders.first {
            selectedFolderId = firstFolder.id
            if let firstSnippet = firstFolder.snippets.first {
                selectedSnippetId = firstSnippet.id
            }
        }
    }
    
    private func loadAdminStatus() {
        let cached = SyncService.shared.getCachedMemberInfo()
        
        if cached.role == nil || cached.department == nil {
            SyncService.shared.refreshMemberInfo {
                let refreshed = SyncService.shared.getCachedMemberInfo()
                let role = refreshed.role ?? ""
                self.userDepartment = refreshed.department ?? ""
                self.isAdmin = (role == "最高管理者" || role == "管理者")
            }
        } else {
            let role = cached.role ?? ""
            userDepartment = cached.department ?? ""
            isAdmin = (role == "最高管理者" || role == "管理者")
        }
    }
    
    private func saveData() {
        let personal = personalFolders
        let master = masterFolders
        DispatchQueue.global(qos: .utility).async {
            StorageService.shared.savePersonalSnippets(personal)
            StorageService.shared.saveMasterSnippets(master)
        }
    }
    
    private func addSnippet(title: String, content: String) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == selectedFolderId }) else {
            if personalFolders.isEmpty {
                let newFolder = SnippetFolder(name: "新規フォルダ", order: 0)
                personalFolders.append(newFolder)
                selectedFolderId = newFolder.id
            }
            guard let index = personalFolders.firstIndex(where: { $0.id == selectedFolderId }) else { return }
            addSnippetToFolder(at: index, title: title, content: content)
            return
        }
        addSnippetToFolder(at: folderIndex, title: title, content: content)
    }
    
    private func addSnippetToFolder(at folderIndex: Int, title: String, content: String) {
        let newSnippet = Snippet(
            title: title,
            content: content,
            folder: personalFolders[folderIndex].name,
            type: .personal,
            order: personalFolders[folderIndex].snippets.count
        )
        
        personalFolders[folderIndex].snippets.append(newSnippet)
        selectedSnippetId = newSnippet.id
        isAddingSnippet = false
        saveData()
    }
    
    // MARK: - Promote/Demote Snippet
    
    private func promoteSnippetToMaster(snippet: Snippet, fromFolderName: String) {
        var targetFolderIndex = masterFolders.firstIndex { $0.name == fromFolderName }
        
        if targetFolderIndex == nil {
            let newFolder = SnippetFolder(
                name: fromFolderName,
                snippets: [],
                order: masterFolders.count
            )
            masterFolders.append(newFolder)
            targetFolderIndex = masterFolders.count - 1
        }
        
        if let index = targetFolderIndex {
            var newSnippet = snippet
            newSnippet.type = .master
            newSnippet.order = masterFolders[index].snippets.count
            masterFolders[index].snippets.append(newSnippet)
            saveData()
        }
    }
    
    private func demoteSnippetToPersonal(snippet: Snippet, fromFolderName: String) {
        var targetFolderIndex = personalFolders.firstIndex { $0.name == fromFolderName }
        
        if targetFolderIndex == nil {
            let newFolder = SnippetFolder(
                name: fromFolderName,
                snippets: [],
                order: personalFolders.count
            )
            personalFolders.append(newFolder)
            targetFolderIndex = personalFolders.count - 1
        }
        
        if let index = targetFolderIndex {
            var newSnippet = snippet
            newSnippet.type = .personal
            newSnippet.order = personalFolders[index].snippets.count
            personalFolders[index].snippets.append(newSnippet)
            saveData()
        }
    }
    
    // MARK: - Promote/Demote Folder
    
    private func promoteFolderToMaster(folder: SnippetFolder) {
        if let existingIndex = masterFolders.firstIndex(where: { $0.name == folder.name }) {
            for snippet in folder.snippets {
                var newSnippet = snippet
                newSnippet.type = .master
                newSnippet.order = masterFolders[existingIndex].snippets.count
                masterFolders[existingIndex].snippets.append(newSnippet)
            }
        } else {
            let newFolder = SnippetFolder(
                id: UUID().uuidString,
                name: folder.name,
                snippets: folder.snippets.map { snippet in
                    Snippet(
                        id: UUID().uuidString,
                        title: snippet.title,
                        content: snippet.content,
                        folder: folder.name,
                        type: .master,
                        description: snippet.description,
                        order: snippet.order
                    )
                },
                order: masterFolders.count
            )
            masterFolders.append(newFolder)
        }
        
        personalFolders.removeAll { $0.id == folder.id }
        saveData()
    }
    
    private func demoteFolderToPersonal(folder: SnippetFolder) {
        if let existingIndex = personalFolders.firstIndex(where: { $0.name == folder.name }) {
            for snippet in folder.snippets {
                var newSnippet = snippet
                newSnippet.type = .personal
                newSnippet.order = personalFolders[existingIndex].snippets.count
                personalFolders[existingIndex].snippets.append(newSnippet)
            }
        } else {
            let newFolder = SnippetFolder(
                id: UUID().uuidString,
                name: folder.name,
                snippets: folder.snippets.map { snippet in
                    Snippet(
                        id: UUID().uuidString,
                        title: snippet.title,
                        content: snippet.content,
                        folder: folder.name,
                        type: .personal,
                        description: snippet.description,
                        order: snippet.order
                    )
                },
                order: personalFolders.count
            )
            personalFolders.append(newFolder)
        }
        
        masterFolders.removeAll { $0.id == folder.id }
        saveData()
    }
    
    // MARK: - Import/Export
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let parser = XMLParserHelper()
                let importedFolders = parser.parse(data: data)
                
                if importTarget == .master {
                    handleMasterImport(importedFolders)
                } else {
                    handlePersonalImport(importedFolders)
                }
            } catch {
                alertMessage = "インポートに失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        case .failure:
            break
        }
    }
    
    private func handleMasterImport(_ importedFolders: [SnippetFolder]) {
        var newFolders: [SnippetFolder] = []
        
        for folder in importedFolders {
            var newSnippets: [Snippet] = []
            for snippet in folder.snippets {
                let newSnippet = Snippet(
                    title: snippet.title,
                    content: snippet.content,
                    folder: folder.name,
                    type: .master,
                    description: snippet.description,
                    order: newSnippets.count
                )
                newSnippets.append(newSnippet)
            }
            let newFolder = SnippetFolder(
                name: folder.name,
                snippets: newSnippets,
                order: newFolders.count
            )
            newFolders.append(newFolder)
        }
        
        isUploading = true
        SyncService.shared.uploadMasterSnippets(folders: newFolders) { [self] result in
            isUploading = false
            switch result {
            case .success:
                masterFolders = newFolders
                alertMessage = "マスタスニペットをアップロードしました"
                showAlert = true
            case .failure(let error):
                alertMessage = "アップロードに失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func handlePersonalImport(_ importedFolders: [SnippetFolder]) {
        var addedFolders = 0
        var addedSnippets = 0
        var updatedSnippets = 0

        for folder in importedFolders {
            if let existingIndex = personalFolders.firstIndex(where: { $0.name == folder.name }) {
                for snippet in folder.snippets {
                    if let snippetIndex = personalFolders[existingIndex].snippets.firstIndex(where: { $0.title == snippet.title }) {
                        personalFolders[existingIndex].snippets[snippetIndex].content = snippet.content
                        personalFolders[existingIndex].snippets[snippetIndex].description = snippet.description
                        updatedSnippets += 1
                    } else {
                        let newSnippet = Snippet(
                            title: snippet.title,
                            content: snippet.content,
                            folder: folder.name,
                            type: .personal,
                            description: snippet.description,
                            order: personalFolders[existingIndex].snippets.count
                        )
                        personalFolders[existingIndex].snippets.append(newSnippet)
                        addedSnippets += 1
                    }
                }
            } else {
                var newSnippets: [Snippet] = []
                for snippet in folder.snippets {
                    let newSnippet = Snippet(
                        title: snippet.title,
                        content: snippet.content,
                        folder: folder.name,
                        type: .personal,
                        description: snippet.description,
                        order: newSnippets.count
                    )
                    newSnippets.append(newSnippet)
                    addedSnippets += 1
                }
                let newFolder = SnippetFolder(
                    name: folder.name,
                    snippets: newSnippets,
                    order: personalFolders.count
                )
                personalFolders.append(newFolder)
                addedFolders += 1
            }
        }

        saveData()
        alertMessage = "インポート完了\n追加: \(addedFolders)フォルダ, \(addedSnippets)スニペット\n更新: \(updatedSnippets)スニペット"
        showAlert = true
    }
    
    private func performExport(selectedFolders: Set<String>, selectedType: ImportExportTarget?) {
        let foldersToExport: [SnippetFolder]
        
        if selectedType == .master {
            foldersToExport = masterFolders.filter { selectedFolders.contains($0.id) }
        } else {
            foldersToExport = personalFolders.filter { selectedFolders.contains($0.id) }
        }
        
        if foldersToExport.isEmpty {
            alertMessage = "フォルダが選択されていません"
            showAlert = true
            return
        }
        
        // エクスポートするフォルダのXMLを生成してDownloadsに保存
        let xmlString = exportFormat == .clipy
            ? XMLParserHelper.exportClipyXML(folders: foldersToExport)
            : XMLParserHelper.exportSnipeeXML(folders: foldersToExport)
        
        let typeString = selectedType == .master ? "master" : "personal"
        let formatString = exportFormat == .snipee ? "snipee" : "clipy"
        let filename = "\(typeString)-snippets-\(formatString).xml"
        
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = downloadsURL.appendingPathComponent(filename)
        
        do {
            try xmlString.write(to: fileURL, atomically: true, encoding: .utf8)
            isShowingExportSheet = false
            alertMessage = "エクスポート完了: Downloads/\(filename)"
            showAlert = true
        } catch {
            alertMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            alertMessage = "エクスポート完了: \(url.lastPathComponent)"
            showAlert = true
        case .failure(let error):
            alertMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func createExportDocument() -> SnippetXMLDocument {
        let foldersToExport: [SnippetFolder]
        
        if exportFormat == .clipy {
            if exportTarget == .master {
                let filtered = masterFolders.filter { selectedExportFolders.contains($0.id) }
                foldersToExport = filtered.map { folder in
                    SnippetFolder(
                        id: folder.id,
                        name: folder.name,
                        snippets: folder.snippets.map { snippet in
                            Snippet(
                                id: snippet.id,
                                title: snippet.title,
                                content: snippet.content,
                                folder: snippet.folder,
                                type: snippet.type,
                                description: "",
                                order: snippet.order
                            )
                        },
                        order: folder.order
                    )
                }
            } else {
                let filtered = personalFolders.filter { selectedExportFolders.contains($0.id) }
                foldersToExport = filtered.map { folder in
                    SnippetFolder(
                        id: folder.id,
                        name: folder.name,
                        snippets: folder.snippets.map { snippet in
                            Snippet(
                                id: snippet.id,
                                title: snippet.title,
                                content: snippet.content,
                                folder: snippet.folder,
                                type: snippet.type,
                                description: "",
                                order: snippet.order
                            )
                        },
                        order: folder.order
                    )
                }
            }
        } else {
            if exportTarget == .master {
                foldersToExport = masterFolders.filter { selectedExportFolders.contains($0.id) }
            } else {
                foldersToExport = personalFolders.filter { selectedExportFolders.contains($0.id) }
            }
        }
        
        return SnippetXMLDocument(folders: foldersToExport)
    }
    
    private func generateExportFilename() -> String {
        let typeString = exportTarget == .master ? "master" : "personal"
        let formatString = exportFormat == .snipee ? "snipee" : "clipy"
        return "\(typeString)-snippets-\(formatString).xml"
    }
    
    private func syncSnippets() {
        saveRequestId += 1
        SyncService.shared.syncMasterSnippets { success in
            DispatchQueue.main.async {
                masterFolders = StorageService.shared.getMasterSnippets()
            }
        }
    }
    
    private func uploadMasterSnippets() {
        saveRequestId += 1
        isUploading = true
        SyncService.shared.uploadMasterSnippets(folders: masterFolders) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success:
                    alertMessage = "マスタスニペットをアップロードしました"
                    showAlert = true
                case .failure(let error):
                    alertMessage = "アップロードに失敗しました: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Binding var selectedType: SnippetEditorView.ImportExportTarget?
    @Binding var selectedFolders: Set<String>
    @Binding var exportFormat: SnippetEditorView.ExportFormat
    
    let personalFolders: [SnippetFolder]
    let masterFolders: [SnippetFolder]
    let isAdmin: Bool
    var onExport: (Set<String>) -> Void
    var onCancel: () -> Void
    
    @State private var localSelectedType: SnippetEditorView.ImportExportTarget? = nil
    @State private var localSelectedFolders: Set<String> = []
    @State private var localExportFormat: SnippetEditorView.ExportFormat = .snipee
    
    var currentFolders: [SnippetFolder] {
        localSelectedType == .master ? masterFolders : personalFolders
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("エクスポート")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("スニペットタイプを選択:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: { localSelectedType = .personal }) {
                        Text("個別")
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(localSelectedType == .personal ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(localSelectedType == .personal ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    if isAdmin {
                        Button(action: { localSelectedType = .master }) {
                            Text("マスタ")
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(localSelectedType == .master ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(localSelectedType == .master ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            if !currentFolders.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("フォルダを選択:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(currentFolders, id: \.id) { folder in
                                HStack {
                                    Image(systemName: localSelectedFolders.contains(folder.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(localSelectedFolders.contains(folder.id) ? .blue : .gray)
                                    
                                    Text(folder.name)
                                        .font(.body)
                                    
                                    Text("(\(folder.snippets.count))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if localSelectedFolders.contains(folder.id) {
                                        localSelectedFolders.remove(folder.id)
                                    } else {
                                        localSelectedFolders.insert(folder.id)
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 120)
                    .background(Color(.textBackgroundColor))
                    .border(Color.gray.opacity(0.3))
                }
            } else {
                Text("選択可能なフォルダがありません")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("エクスポート形式:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: { localExportFormat = .snipee }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Snipeeに取り込む場合")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Description情報を含む")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(localExportFormat == .snipee ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .border(localExportFormat == .snipee ? Color.blue : Color.gray.opacity(0.3), width: 1)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { localExportFormat = .clipy }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clipyに取り込む場合")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Clipy互換形式（XML）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(localExportFormat == .clipy ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .border(localExportFormat == .clipy ? Color.blue : Color.gray.opacity(0.3), width: 1)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("キャンセル", action: onCancel)
                    .keyboardShortcut(.escape)
                
                Button("エクスポート") {
                    selectedType = localSelectedType
                    exportFormat = localExportFormat
                    onExport(localSelectedFolders)
                }
                .keyboardShortcut(.return)
                .disabled(localSelectedType == nil || localSelectedFolders.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 480, height: 480)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            localSelectedType = selectedType ?? .personal
        }
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
                .foregroundColor(Color(.labelColor))
            
            TextField("タイトル", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .frame(height: 120)
                .scrollContentBackground(.hidden)
                .background(Color(.textBackgroundColor))
                .border(Color(.separatorColor))
            
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
        .background(Color(.windowBackgroundColor))
    }
}
