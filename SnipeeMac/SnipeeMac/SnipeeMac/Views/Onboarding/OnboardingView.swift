//
//  OnboardingView.swift
//  SnipeeMac
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var isLoggedIn = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
            
            VStack(spacing: 0) {
                // Close button (only if logged in)
                HStack {
                    Spacer()
                    if isLoggedIn {
                        Button(action: {
                            markCompleted()
                            onComplete()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                
                // Content
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        loginStep
                    case 2:
                        permissionStep
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            isLoggedIn = GoogleAuthService.shared.isLoggedIn
        }
    }
    
    // MARK: - Step 1: Welcome
    
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Snipeeへようこそ！")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("クリップボード履歴とスニペットで\n作業効率をアップしましょう")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { currentStep = 1 }) {
                Text("次へ")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Step 2: Login
    
    private var loginStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Googleでログイン")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Snipeeを使用するには\nログインが必要です")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isLoggedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("ログイン済み")
                }
                
                Button(action: { currentStep = 2 }) {
                    Text("次へ")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: login) {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Googleでログイン")
                    }
                    .frame(width: 180)
                }
                .buttonStyle(.borderedProminent)
                
                if let error = loginError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text("※ログインしないと使用できません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Step 3: Permission
    
    private var permissionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("アクセシビリティ権限")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("ホットキーと自動ペーストに必要です")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: openAccessibility) {
                HStack {
                    Image(systemName: "gear")
                    Text("システム設定を開く")
                }
                .frame(width: 180)
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                markCompleted()
                onComplete()
            }) {
                Text("完了")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Actions
    
    @State private var loginError: String?
    
    private func login() {
        loginError = nil
        
        GoogleAuthService.shared.startOAuthFlow { result in
            switch result {
            case .success:
                // スプシでメンバー確認
                self.verifyMembership()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loginError = error.localizedDescription
                }
            }
        }
    }
    
    private func verifyMembership() {
        guard let email = GoogleAuthService.shared.userEmail else {
            DispatchQueue.main.async {
                self.loginError = "メールアドレスを取得できませんでした"
                GoogleAuthService.shared.logout()
            }
            return
        }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // メンバー確認OK
                    self.isLoggedIn = true
                    
                case .failure:
                    // メンバーリストにない → ログアウト
                    GoogleAuthService.shared.logout()
                    self.loginError = "メンバーリストに登録されていません。\n管理者に連絡してください。"
                }
            }
        }
    }
    
    private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func markCompleted() {
        var settings = StorageService.shared.getSettings()
        settings.onboardingCompleted = true
        StorageService.shared.saveSettings(settings)
    }
}
