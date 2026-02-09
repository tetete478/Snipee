//
//  PersonalSnippetsView.swift
//  SnipeeIOS
//

import SwiftUI

struct PersonalSnippetsView: View {
    @EnvironmentObject var appState: AppState
    @State private var expandedFolders: Set<String> = []
    
    private var personalFolders: [SnippetFolder] {
        appState.folders.compactMap { folder in
            let personalSnippets = folder.snippets.filter { $0.type == .personal }
            if personalSnippets.isEmpty { return nil }
            var newFolder = folder
            newFolder.snippets = personalSnippets
            return newFolder
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if personalFolders.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("個別スニペット")
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("個別スニペットがありません")
                .foregroundColor(.secondary)
            Text("Mac版で個別スニペットを作成すると\nここに表示されます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var listView: some View {
        List {
            ForEach(personalFolders) { folder in
                Section {
                    ForEach(folder.snippets) { snippet in
                        SnippetRow(snippet: snippet)
                    }
                } header: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(ColorTheme.primary)
                        Text(folder.name)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.title)
                .font(.headline)
            Text(snippet.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            copyToClipboard()
        }
    }
    
    private func copyToClipboard() {
        let processedContent = VariableService.shared.process(snippet.content)
        UIPasteboard.general.string = processedContent
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    PersonalSnippetsView()
        .environmentObject(AppState())
}
