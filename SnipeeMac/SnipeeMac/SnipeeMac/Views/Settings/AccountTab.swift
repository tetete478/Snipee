
//
//  AccountTab.swift
//  SnipeeMac
//

import SwiftUI

struct AccountTab: View {
    @State private var isLoggedIn = false
    @State private var userEmail = ""
    @State private var userName = ""
    @State private var userRole = ""
    @State private var departments: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoggedIn {
                // Logged in state
                VStack(alignment: .leading, spacing: 12) {
                    Text("ログイン中")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(userName)
                                .font(.headline)
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("権限:")
                        Text(userRole)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("部署:")
                        Text(departments.joined(separator: ", "))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Button(action: logout) {
                        Text("ログアウト")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Logged out state
                VStack(alignment: .leading, spacing: 12) {
                    Text("Googleアカウント")
                        .font(.headline)
                    
                    Text("ログインすると、マスタスニペットが使用できます")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: login) {
                        HStack {
                            Image(systemName: "person.badge.key.fill")
                            Text("Googleでログイン")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Text("※ @team.addness.co.jp のアカウントでログインしてください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onAppear {
            checkLoginStatus()
        }
    }
    
    private func checkLoginStatus() {
        if let email = KeychainHelper.shared.get(Constants.Keychain.userEmail) {
            isLoggedIn = true
            userEmail = email
            // TODO: Load user info from cache
        }
    }
    
    private func login() {
        // TODO: Implement Google OAuth
        print("Login tapped")
    }
    
    private func logout() {
        KeychainHelper.shared.clearAll()
        isLoggedIn = false
        userEmail = ""
        userName = ""
        userRole = ""
        departments = []
    }
}
