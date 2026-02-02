//
//  SearchView.swift
//  SnipeeIOS
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var allSnippets: [Snippet] = []
    @State private var showToast = false
    @State private var toastMessage = ""

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return allSnippets
        }
        return allSnippets.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSnippets) { snippet in
                    SnippetRowView(snippet: snippet) {
                        copySnippet(snippet)
                    }
                }
            }
            .navigationTitle("検索")
            .searchable(text: $searchText, prompt: "スニペットを検索")
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay {
                if filteredSnippets.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        let folders = StorageService.shared.getSnippets()
        allSnippets = folders.flatMap { $0.snippets }
    }

    private func copySnippet(_ snippet: Snippet) {
        let processed = VariableService.shared.process(snippet.content)
        UIPasteboard.general.string = processed
        showToastMessage("コピーしました")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

#Preview {
    SearchView()
}
