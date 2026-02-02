//
//  FolderListView.swift
//  SnipeeIOS
//

import SwiftUI

struct FolderListView: View {
    @EnvironmentObject var appState: AppState

    private var masterFolders: [SnippetFolder] {
        appState.folders.filter { folder in
            folder.snippets.contains { $0.type == .master }
        }
    }

    private var personalFolders: [SnippetFolder] {
        appState.folders.filter { folder in
            folder.snippets.contains { $0.type == .personal }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.folders.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        if !masterFolders.isEmpty {
                            Section("マスタ") {
                                ForEach(masterFolders) { folder in
                                    NavigationLink(destination: FolderDetailView(folder: folder)) {
                                        FolderRowView(folder: folder, isMaster: true)
                                    }
                                }
                            }
                        }

                        if !personalFolders.isEmpty {
                            Section("個別") {
                                ForEach(personalFolders) { folder in
                                    NavigationLink(destination: FolderDetailView(folder: folder)) {
                                        FolderRowView(folder: folder, isMaster: false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("フォルダ")
            .refreshable {
                await appState.refresh()
            }
        }
    }
}

// MARK: - Folder Row

struct FolderRowView: View {
    let folder: SnippetFolder
    let isMaster: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundColor(isMaster ? ColorTheme.primary : .blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.headline)

                Text("\(folder.snippets.count) スニペット")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FolderListView()
        .environmentObject(AppState())
}
