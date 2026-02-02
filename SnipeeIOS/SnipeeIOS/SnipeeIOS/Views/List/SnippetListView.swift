//
//  SnippetListView.swift
//  SnipeeIOS
//

import SwiftUI

struct SnippetListView: View {
    @State private var folders: [SnippetFolder] = []
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders) { folder in
                    Section(header: Text(folder.name)) {
                        ForEach(folder.snippets) { snippet in
                            SnippetRowView(snippet: snippet) {
                                copySnippet(snippet)
                            }
                        }
                    }
                }
            }
            .navigationTitle("スニペット")
            .refreshable {
                await refreshData()
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
            .padding(.bottom, 20)
    }
}

#Preview {
    SnippetListView()
}
