//
//  SnippetImportExportService.swift
//  SnipeeMac
//
//  スニペットのインポート/エクスポート処理

import Foundation
import UniformTypeIdentifiers
import SwiftUI

// MARK: - Import/Export Target

enum ImportExportTarget {
    case personal
    case master
}

// MARK: - Import Result

enum ImportResult {
    case personal(folders: [SnippetFolder], message: String)
    case master(folders: [SnippetFolder], message: String)
    case failure(Error)
}

// MARK: - Import/Export Service

struct SnippetImportExportService {

    // MARK: - Import

    /// インポート処理のメインエントリーポイント
    static func handleImport(
        _ result: Result<[URL], Error>,
        target: ImportExportTarget?,
        currentPersonalFolders: [SnippetFolder],
        onMasterUpload: @escaping ([SnippetFolder], @escaping (Result<Void, Error>) -> Void) -> Void,
        completion: @escaping (ImportResult) -> Void
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let parser = XMLParserHelper()
                let importedFolders = parser.parse(data: data)

                if target == .master {
                    handleMasterImport(
                        importedFolders,
                        onUpload: onMasterUpload,
                        completion: completion
                    )
                } else {
                    var personalFolders = currentPersonalFolders
                    let message = applyPersonalImport(importedFolders, to: &personalFolders)
                    completion(.personal(folders: personalFolders, message: message))
                }
            } catch {
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    /// マスタスニペットのインポート処理
    private static func handleMasterImport(
        _ importedFolders: [SnippetFolder],
        onUpload: @escaping ([SnippetFolder], @escaping (Result<Void, Error>) -> Void) -> Void,
        completion: @escaping (ImportResult) -> Void
    ) {
        let newFolders = buildMasterFolders(from: importedFolders)

        onUpload(newFolders) { result in
            switch result {
            case .success:
                completion(.master(folders: newFolders, message: "マスタスニペットをアップロードしました"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// インポートされたフォルダからマスタフォルダを構築
    private static func buildMasterFolders(from importedFolders: [SnippetFolder]) -> [SnippetFolder] {
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

        return newFolders
    }

    /// 個別スニペットのインポート処理
    private static func applyPersonalImport(
        _ importedFolders: [SnippetFolder],
        to personalFolders: inout [SnippetFolder]
    ) -> String {
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

        return "インポート完了\n追加: \(addedFolders)フォルダ, \(addedSnippets)スニペット\n更新: \(updatedSnippets)スニペット"
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
