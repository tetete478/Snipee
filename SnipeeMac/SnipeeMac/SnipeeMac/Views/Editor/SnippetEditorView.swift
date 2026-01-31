//
//  SnippetEditorView.swift
//  SnipeeMac
//

import SwiftUI
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
    @State private var allDepartments: [DepartmentInfo] = []
    @State private var selectedOtherDepartment: DepartmentInfo?
    @State private var otherDepartmentFolders: [SnippetFolder] = []
    @State private var isLoadingOtherDepartment = false
    @State private var isViewingOtherDepartment = false
    @State private var saveRequestId: Int = 0

    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    enum ImportExportTarget {
        case personal
        case master
    }
    
    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            
            Divider()
            
            mainContent
        }
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
        .fileExporter(
            isPresented: $isExporting,
            document: SnippetXMLDocument(folders: exportTarget == .master ? masterFolders : personalFolders),
            contentType: .xml,
            defaultFilename: exportTarget == .master ? "master-snippets.xml" : "personal-snippets.xml"
        ) { result in
            handleExport(result)
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
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        HSplitView {
            sidebarView
            contentPanelView
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
            isReadOnly: isViewingOtherDepartment,
            onSave: saveData,
            onPromoteSnippet: promoteSnippetToMaster,
            onDemoteSnippet: demoteSnippetToPersonal,
            onPromoteFolder: promoteFolderToMaster,
            onDemoteFolder: demoteFolderToPersonal
        )
        .frame(minWidth: 200, maxWidth: 280)
    }
    
    private var currentMasterFolders: Binding<[SnippetFolder]> {
        isViewingOtherDepartment ? $otherDepartmentFolders : $masterFolders
    }
    
    private var currentContentFolders: Binding<[SnippetFolder]> {
        if isShowingMaster {
            return isViewingOtherDepartment ? $otherDepartmentFolders : $masterFolders
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
            isReadOnly: isViewingOtherDepartment,
            isAdmin: isAdmin,
            onSave: { if !isViewingOtherDepartment { saveData() } },
            onAddSnippet: { if !isViewingOtherDepartment { isAddingSnippet = true } },
            saveRequestId: $saveRequestId
        )
        .id("content-\(isViewingOtherDepartment)-\(selectedFolderId ?? "")")
        .frame(minWidth: 400)
    }
    
    // MARK: - Editor Toolbar
    
    private var editorToolbar: some View {
        HStack {
            Spacer()
            
            if isAdmin {
                otherDepartmentButton
            }
            
            Button(action: { syncSnippets() }) {
                Label("同期", systemImage: "arrow.triangle.2.circlepath")
            }
            
            importMenu
            exportMenu
            
            if isAdmin && !isViewingOtherDepartment {
                Button(action: uploadMasterSnippets) {
                    Label("マスタ更新", systemImage: "icloud.and.arrow.up")
                }
                .help("マスタスニペットをアップロード")
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
    
    @ViewBuilder
    private var otherDepartmentButton: some View {
        if isViewingOtherDepartment {
            Button(action: closeOtherDepartmentView) {
                HStack(spacing: 4) {
                    Text(selectedOtherDepartment?.name ?? "")
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .foregroundColor(.orange)
        } else {
            Menu {
                ForEach(allDepartments.filter { $0.name != userDepartment }, id: \.name) { dept in
                    Button(dept.name) {
                        selectedOtherDepartment = dept
                        loadOtherDepartmentSnippets()
                    }
                }
            } label: {
                Label("他部署マスタ", systemImage: "building.2")
            }
        }
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
    
    private var exportMenu: some View {
        Menu {
            Button("個別スニペット") {
                exportTarget = .personal
                isExporting = true
            }
            .disabled(personalFolders.isEmpty)
            if isAdmin {
                Button("マスタスニペット") {
                    exportTarget = .master
                    isExporting = true
                }
                .disabled(masterFolders.isEmpty)
            }
        } label: {
            Label("エクスポート", systemImage: "square.and.arrow.up")
        }
        .help("XMLファイルに書き出す")
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
        
        // キャッシュが空なら再取得
        if cached.role == nil || cached.department == nil {
            SyncService.shared.refreshMemberInfo {
                let refreshed = SyncService.shared.getCachedMemberInfo()
                let role = refreshed.role ?? ""
                self.userDepartment = refreshed.department ?? ""
                self.isAdmin = (role == "最高管理者" || role == "管理者")
                
                if self.isAdmin {
                    self.loadAllDepartments()
                }
            }
        } else {
            let role = cached.role ?? ""
            userDepartment = cached.department ?? ""
            isAdmin = (role == "最高管理者" || role == "管理者")
            
            if isAdmin {
                loadAllDepartments()
            }
        }
    }
    
    private func loadAllDepartments() {
        GoogleSheetsService.shared.fetchAllDepartments { result in
            switch result {
            case .success(let departments):
                allDepartments = departments
            case .failure(let error):
                print("Failed to load departments: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadOtherDepartmentSnippets() {
        guard let dept = selectedOtherDepartment else {
            print("⚠️ loadOtherDepartmentSnippets - no department selected")
            return
        }
        print("🏢 loadOtherDepartmentSnippets - dept: \(dept.name), fileId: \(dept.fileId)")
        isLoadingOtherDepartment = true
        
        GoogleDriveService.shared.downloadXMLFile(fileId: dept.fileId) { result in
            print("📥 downloadXMLFile result received")
            DispatchQueue.main.async {
                isLoadingOtherDepartment = false
                switch result {
                case .success(let data):
                    let parser = XMLParserHelper()
                    otherDepartmentFolders = parser.parse(data: data)
                    
                    // 先にフラグを設定
                    isShowingMaster = true
                    isViewingOtherDepartment = true
                    
                    // その後でIDを設定
                    if let firstFolder = otherDepartmentFolders.first {
                        selectedFolderId = firstFolder.id
                        if let firstSnippet = firstFolder.snippets.first {
                            selectedSnippetId = firstSnippet.id
                        }
                    }
                    
                    alertMessage = "読み込み完了: \(otherDepartmentFolders.count)フォルダ"
                    showAlert = true
                case .failure(let error):
                    alertMessage = "読み込みに失敗しました: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func closeOtherDepartmentView() {
        isViewingOtherDepartment = false
        selectedOtherDepartment = nil
        otherDepartmentFolders = []
    }
    
    private func saveData() {
        StorageService.shared.savePersonalSnippets(personalFolders)
        StorageService.shared.saveMasterSnippets(masterFolders)
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
        case .failure(let error):
            print("Import failed: \(error)")
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
    
    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to: \(url)")
        case .failure(let error):
            print("Export failed: \(error)")
        }
    }
    
    private func syncSnippets() {
        saveRequestId += 1  // 即時保存をトリガー
        SyncService.shared.syncMasterSnippets { success in
            DispatchQueue.main.async {
                masterFolders = StorageService.shared.getMasterSnippets()
            }
        }
    }
    
    private func uploadMasterSnippets() {
        saveRequestId += 1  // 即時保存をトリガー
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
                .frame(height: 150)
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

// MARK: - XML Document for Export

struct SnippetXMLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xml] }
    
    var folders: [SnippetFolder]
    
    init(folders: [SnippetFolder]) {
        self.folders = folders
    }
    
    init(configuration: ReadConfiguration) throws {
        folders = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let xmlString = XMLParserHelper.export(folders: folders)
        let data = xmlString.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
