//
//  SnippetRowView.swift
//  SnipeeIOS
//

import SwiftUI

struct SnippetRowView: View {
    let snippet: Snippet
    let onCopy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(snippet.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 20))
                    .foregroundColor(ColorTheme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SnippetRowView(
        snippet: Snippet(
            title: "サンプル",
            content: "これはサンプルのスニペットです。\n2行目のテキスト。",
            folder: "テスト",
            type: .master,
            order: 0
        ),
        onCopy: {}
    )
    .padding()
}
