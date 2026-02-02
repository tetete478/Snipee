//
//  SnippetPromotionService.swift
//  SnipeeMac
//
//  スニペット・フォルダの昇格/降格処理

import Foundation

struct SnippetPromotionService {

    // MARK: - Snippet Promotion

    /// スニペットをマスタに昇格
    static func promoteSnippetToMaster(
        snippet: Snippet,
        fromFolderName: String,
        masterFolders: inout [SnippetFolder]
    ) {
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
        }
    }

    /// スニペットを個別に降格
    static func demoteSnippetToPersonal(
        snippet: Snippet,
        fromFolderName: String,
        personalFolders: inout [SnippetFolder]
    ) {
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
        }
    }

    // MARK: - Folder Promotion

    /// フォルダをマスタに昇格
    static func promoteFolderToMaster(
        folder: SnippetFolder,
        masterFolders: inout [SnippetFolder],
        personalFolders: inout [SnippetFolder]
    ) {
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
    }

    /// フォルダを個別に降格
    static func demoteFolderToPersonal(
        folder: SnippetFolder,
        masterFolders: inout [SnippetFolder],
        personalFolders: inout [SnippetFolder]
    ) {
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
    }
}
