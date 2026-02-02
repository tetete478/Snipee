//
//  KeyboardMainView.swift
//  SnipeeKeyboard
//

import SwiftUI

struct KeyboardMainView: View {
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void

    @State private var folders: [SnippetFolder] = []
    @State private var selectedFolderIndex = 0

    private var currentSnippets: [Snippet] {
        guard selectedFolderIndex < folders.count else { return [] }
        return folders[selectedFolderIndex].snippets
    }

    var body: some View {
        VStack(spacing: 0) {
            // Folder tabs
            FolderTabBar(
                folders: folders,
                selectedIndex: $selectedFolderIndex
            )

            // Snippet grid
            SnippetGridView(
                snippets: currentSnippets,
                onSelect: { snippet in
                    onInsertText(snippet.content)
                }
            )

            // Bottom bar
            HStack {
                Button(action: onDeleteBackward) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
        }
        .frame(height: 260)
        .background(Color(.systemBackground))
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        folders = StorageService.shared.getSnippets()
    }
}

#Preview {
    KeyboardMainView(
        onInsertText: { _ in },
        onDeleteBackward: {}
    )
}
