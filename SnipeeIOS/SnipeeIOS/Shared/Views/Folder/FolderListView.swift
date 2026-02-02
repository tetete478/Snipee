//
//  FolderListView.swift
//  SnipeeIOS
//

import SwiftUI

struct FolderListView: View {
    @State private var folders: [SnippetFolder] = []

    var body: some View {
        NavigationStack {
            List {
                Section("マスタ") {
                    ForEach(folders.filter { $0.snippets.first?.type == .master }) { folder in
                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                            FolderRowView(folder: folder, isMaster: true)
                        }
                    }
                }

                Section("個別") {
                    ForEach(folders.filter { $0.snippets.first?.type == .personal }) { folder in
                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                            FolderRowView(folder: folder, isMaster: false)
                        }
                    }
                }
            }
            .navigationTitle("フォルダ")
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        folders = StorageService.shared.getSnippets()
    }

    private func refreshData() async {
        await SyncService.shared.syncMasterSnippets()
        loadData()
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
}
