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

    private let theme = ColorTheme(rawValue: StorageService.shared.getSettings().theme) ?? .silver
    
    var body: some View {
        HSplitView {
            // Left: 階層式サイドバー
            FolderSidebar(
                personalFolders: $personalFolders,
                masterFolders: $masterFolders,
                selectedFolderId: $selectedFolderId,
                selectedSnippetId: $selectedSnippetId,
                isShowingMaster: $isShowingMaster,
                onSave: saveData
            )
            .frame(minWidth: 200, maxWidth: 280)
            
            // Right: エディタパネル
            ContentPanel(
                folders: isShowingMaster ? $masterFolders : $personalFolders,
                selectedFolderId: $selectedFolderId,
                selectedSnippetId: $selectedSnippetId,
                isShowingMaster: isShowingMaster,
                onSave: saveData,
                onPromoteToMaster: promoteToMaster,
                onAddSnippet: { isAddingSnippet = true }
            )
            .frame(minWidth: 400)
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            loadData()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: { syncSnippets() }) {
                        Label("同期", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button(action: { isImporting = true }) {
                        Label("インポート", systemImage: "square.and.arrow.down")
                    }
                    .help("XMLファイルを読み込む")

                    Button(action: { isExporting = true }) {
                        Label("エクスポート", systemImage: "square.and.arrow.up")
                    }
                    .help("XMLファイルに書き出す")
                    .disabled(personalFolders.isEmpty)
                }
            }
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
            document: SnippetXMLDocument(folders: personalFolders),
                contentType: .xml,
                defaultFilename: "snippets.xml"
            ) { result in
                handleExport(result)
            }
            .sheet(isPresented: $isAddingSnippet) {
            AddSnippetSheet(
                onAdd: addSnippet,
                onCancel: { isAddingSnippet = false }
            )
        }
    }
    
    private func loadData() {
        personalFolders = StorageService.shared.getPersonalSnippets()
        masterFolders = StorageService.shared.getMasterSnippets()
        
        // 最初のフォルダとスニペットを選択
        if let firstFolder = personalFolders.first {
            selectedFolderId = firstFolder.id
            if let firstSnippet = firstFolder.snippets.first {
                selectedSnippetId = firstSnippet.id
            }
        }
    }
    
    private func saveData() {
        StorageService.shared.savePersonalSnippets(personalFolders)
        StorageService.shared.saveMasterSnippets(masterFolders)
    }
    
    private func addSnippet(title: String, content: String) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == selectedFolderId }) else {
            // フォルダ未選択の場合、最初のフォルダに追加
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
    
    private func promoteToMaster(snippet: Snippet, fromFolderName: String) {
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
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let parser = XMLParserHelper()
                let importedFolders = parser.parse(data: data)
                
                for folder in importedFolders {
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
                    }
                    let newFolder = SnippetFolder(
                        name: folder.name,
                        snippets: newSnippets,
                        order: personalFolders.count
                    )
                    personalFolders.append(newFolder)
                }
                
                saveData()
            } catch {
                print("Import error: \(error)")
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
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
        SyncService.shared.syncMasterSnippets { success in
            DispatchQueue.main.async {
                masterFolders = StorageService.shared.getMasterSnippets()
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
