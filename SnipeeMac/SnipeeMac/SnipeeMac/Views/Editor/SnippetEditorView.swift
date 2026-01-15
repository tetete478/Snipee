
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
    @State private var isExporting: Bool = false

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
                onSave: saveData,
                onPromoteToMaster: promoteToMaster
            )
            .frame(minWidth: 400)
        }
        .frame(minWidth: 700, minHeight: 400)
        .onAppear {
            loadData()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: { isImporting = true }) {
                        Label("インポート", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: { isExporting = true }) {
                        Label("エクスポート", systemImage: "square.and.arrow.up")
                    }
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
            document: XMLDocument(folders: personalFolders),
            contentType: .xml,
            defaultFilename: "snippets.xml"
        ) { result in
            handleExport(result)
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
}


// MARK: - XML Document for Export

struct XMLDocument: FileDocument {
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
