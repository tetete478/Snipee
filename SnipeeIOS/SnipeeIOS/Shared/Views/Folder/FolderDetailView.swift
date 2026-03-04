//
//  FolderDetailView.swift
//  SnipeeIOS
//

import SwiftUI

struct FolderDetailView: View {
    let folder: SnippetFolder
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        List {
            ForEach(folder.snippets) { snippet in
                SnippetRowView(snippet: snippet) {
                    copySnippet(snippet)
                }
            }
        }
        .navigationTitle(folder.name)
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(message: toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
    NavigationStack {
        FolderDetailView(folder: SnippetFolder(
            name: "サンプルフォルダ",
            snippets: [
                Snippet(title: "テスト1", content: "内容1", folder: "サンプル", type: .master, order: 0),
                Snippet(title: "テスト2", content: "内容2", folder: "サンプル", type: .master, order: 1)
            ],
            order: 0
        ))
    }
}
