//
//  MainTabView.swift
//  SnipeeIOS
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
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
    }
}

#Preview {
    MainTabView()
}
