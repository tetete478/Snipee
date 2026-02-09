//
//  SnippetListView.swift
//  SnipeeIOS
//

import SwiftUI

struct SnippetListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if appState.isInitialLoading {
                    // 初期ロード中（通常は表示されない）
                    ProgressView("読み込み中...")
                } else if appState.folders.isEmpty {
                    // データなし
                    EmptyStateView()
                } else {
                    // データあり
                    List {
                        ForEach(appState.folders) { folder in
                            Section(header: Text(folder.name)) {
                                ForEach(folder.snippets) { snippet in
                                    SnippetRowView(snippet: snippet) {
                                        copySnippet(snippet)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("スニペット")
            .refreshable {
                await appState.refresh()
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("スニペットがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("プルダウンで同期するか\n設定から接続してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .environmentObject(AppState())
}
