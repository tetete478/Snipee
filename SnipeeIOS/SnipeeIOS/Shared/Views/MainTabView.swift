//
//  MainTabView.swift
//  SnipeeIOS
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                SnippetListView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("一覧")
                    }
                    .tag(0)

                FolderListView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("フォルダ")
                    }
                    .tag(1)

                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("検索")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("設定")
                    }
                    .tag(3)
            }
            .tint(ColorTheme.primary)

            // 同期中インジケーター（上部に表示）
            if appState.isSyncing {
                VStack {
                    SyncingIndicator()
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { gesture in
                    // 同期中はスワイプを無視
                    guard !appState.isSyncing else { return }

                    let horizontal = gesture.translation.width
                    let vertical = gesture.translation.height

                    // 横方向のスワイプのみ反応
                    guard abs(horizontal) > abs(vertical) else { return }

                    if horizontal < -50 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = min(selectedTab + 1, 3)
                        }
                    } else if horizontal > 50 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = max(selectedTab - 1, 0)
                        }
                    }
                }
        )
    }
}

// MARK: - Syncing Indicator

struct SyncingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            Text("同期中...")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ColorTheme.primary.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding(.top, 8)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
