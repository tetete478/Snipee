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
                
                PersonalSnippetsView()
                    .tabItem {
                        Image(systemName: "person.crop.rectangle.stack")
                        Text("個別")
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
