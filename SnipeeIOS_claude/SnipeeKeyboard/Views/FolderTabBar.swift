//
//  FolderTabBar.swift
//  SnipeeKeyboard
//

import SwiftUI

struct FolderTabBar: View {
    let folders: [SnippetFolder]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                    FolderTab(
                        name: folder.name,
                        isSelected: index == selectedIndex,
                        onTap: { selectedIndex = index }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(.secondarySystemBackground))
    }
}

struct FolderTab: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ColorTheme.primary : Color(.tertiarySystemBackground))
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FolderTabBar(
        folders: [
            SnippetFolder(name: "営業", snippets: [], order: 0),
            SnippetFolder(name: "サポート", snippets: [], order: 1),
            SnippetFolder(name: "テンプレート", snippets: [], order: 2)
        ],
        selectedIndex: .constant(0)
    )
}
