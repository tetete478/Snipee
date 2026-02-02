//
//  AccountView.swift
//  SnipeeIOS
//

import SwiftUI

struct AccountView: View {
    @State private var email: String = ""
    @State private var department: String = ""
    @State private var role: String = ""
    @State private var showLogoutAlert = false

    var body: some View {
        List {
            Section("ログイン情報") {
                HStack {
                    Text("メール")
                    Spacer()
                    Text(email)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("部署")
                    Spacer()
                    Text(department)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("権限")
                    Spacer()
                    Text(role)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive, action: { showLogoutAlert = true }) {
                    HStack {
                        Spacer()
                        Text("ログアウト")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("アカウント")
        .alert("ログアウト", isPresented: $showLogoutAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("ログアウト", role: .destructive) {
                logout()
            }
        } message: {
            Text("ログアウトすると、再度ログインが必要になります。")
        }
        .onAppear {
            loadAccountInfo()
        }
    }

    private func loadAccountInfo() {
        let info = SyncService.shared.getCachedMemberInfo()
        email = GoogleAuthService.shared.currentUserEmail ?? ""
        department = info.department ?? ""
        role = info.role ?? ""
    }

    private func logout() {
        SecurityService.shared.logout()
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
}
