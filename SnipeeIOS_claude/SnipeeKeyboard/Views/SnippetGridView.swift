//
//  SnippetGridView.swift
//  SnipeeKeyboard
//

import SwiftUI

struct SnippetGridView: View {
    let snippets: [Snippet]
    let onSelect: (Snippet) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(snippets) { snippet in
                    SnippetCell(snippet: snippet) {
                        onSelect(snippet)
                    }
                }
            }
            .padding(8)
        }
    }
}

struct SnippetCell: View {
    let snippet: Snippet
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(snippet.content)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SnippetGridView(
        snippets: [
            Snippet(title: "挨拶", content: "お世話になっております。", folder: "営業", type: .master, order: 0),
            Snippet(title: "締め", content: "よろしくお願いいたします。", folder: "営業", type: .master, order: 1),
            Snippet(title: "確認", content: "ご確認ください。", folder: "営業", type: .master, order: 2),
            Snippet(title: "お礼", content: "ありがとうございます。", folder: "営業", type: .master, order: 3)
        ],
        onSelect: { _ in }
    )
}
