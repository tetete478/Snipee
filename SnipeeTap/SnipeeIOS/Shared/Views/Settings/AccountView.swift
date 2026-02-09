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
    @State private var isLoggedIn: Bool = false
    @State private var isLoggingIn: Bool = false
    @State private var isLoggingOut: Bool = false

    var body: some View {
        List {
            if !isLoggedIn {
                Section {
                    Button(action: login) {
                        HStack {
                            Spacer()
                            if isLoggingIn {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("ログイン中...")
                            } else {
                                Image(systemName: "person.circle")
                                Text("Googleでログイン")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoggingIn)
                }
            }
            
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
        isLoggedIn = SecurityService.shared.isLoggedIn()
        if isLoggedIn {
            let info = SyncService.shared.getCachedMemberInfo()
            email = GoogleAuthService.shared.currentUserEmail ?? ""
            department = info.department ?? ""
            role = info.role ?? ""
        }
    }
    
    private func login() {
        isLoggingIn = true
        Task {
            do {
                try await GoogleAuthService.shared.signIn()
                await MainActor.run {
                    isLoggingIn = false
                    loadAccountInfo()
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    print("Login error: \(error)")
                }
            }
        }
    }

    private func logout() {
        isLoggingOut = true
        Task {
            await Task.detached {
                SecurityService.shared.logout()
            }.value
            await MainActor.run {
                isLoggingOut = false
                loadAccountInfo()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
}
