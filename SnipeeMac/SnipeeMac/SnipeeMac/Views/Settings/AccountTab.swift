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
    @State private var userDepartment = ""
    @State private var isSyncing = false
    @State private var lastSyncDate: Date?
    @State private var syncError: String?
    
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
                        Text(userRole.isEmpty ? "-" : userRole)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("部署:")
                        Text(userDepartment.isEmpty ? "-" : userDepartment)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Sync Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: syncNow) {
                                HStack {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text(isSyncing ? "同期中..." : "マスタを同期")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isSyncing)
                            
                            Spacer()
                        }
                        
                        if let lastSync = lastSyncDate {
                            Text("最終同期: \(formatDate(lastSync))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let error = syncError {
                            Text("エラー: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
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
            loadCachedInfo()
        }
    }
    
    private func checkLoginStatus() {
        isLoggedIn = GoogleAuthService.shared.isLoggedIn
        if let email = GoogleAuthService.shared.userEmail {
            userEmail = email
            userName = email.components(separatedBy: "@").first ?? ""
        }
        lastSyncDate = StorageService.shared.getSettings().lastSyncDate
    }
    
    private func loadCachedInfo() {
        let cached = SyncService.shared.getCachedMemberInfo()
        if let name = cached.name { userName = name }
        if let dept = cached.department { userDepartment = dept }
        if let role = cached.role { userRole = role }
    }
    
    private func login() {
        GoogleAuthService.shared.startOAuthFlow { result in
            switch result {
            case .success:
                checkLoginStatus()
                // Fetch member info immediately
                fetchMemberInfoOnly()
            case .failure(let error):
                print("Login failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchMemberInfoOnly() {
        guard let email = GoogleAuthService.shared.userEmail else {
            syncNow()
            return
        }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { result in
            switch result {
            case .success(let member):
                userName = member.name
                userDepartment = member.department
                userRole = member.role
                // Then sync master snippets
                syncNow()
            case .failure:
                // Fallback to sync
                syncNow()
            }
        }
    }
    
    private func logout() {
        GoogleAuthService.shared.logout()
        isLoggedIn = false
        userEmail = ""
        userName = ""
        userRole = ""
        userDepartment = ""
    }
    
    private func syncNow() {
        isSyncing = true
        syncError = nil
        
        SyncService.shared.syncMasterSnippets { result in
            isSyncing = false
            
            switch result {
            case .success(let syncResult):
                lastSyncDate = syncResult.syncDate
                if let name = syncResult.memberName { userName = name }
                if let dept = syncResult.memberDepartment { userDepartment = dept }
                if let role = syncResult.memberRole { userRole = role }
                print("Sync success: \(syncResult.folderCount) folders, \(syncResult.snippetCount) snippets")
            case .failure(let error):
                syncError = error.localizedDescription
                print("Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
