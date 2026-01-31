//
//  LoginRequiredView.swift
//  SnipeeMac
//

import SwiftUI

struct LoginRequiredView: View {
    @State private var isLoggingIn = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("ログインが必要です")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Snipeeを使用するには\n社内アカウントでログインしてください")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: login) {
                HStack {
                    if isLoggingIn {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isLoggingIn ? "ログイン中..." : "Googleでログイン")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn)
            
            Button("終了") {
                NSApp.terminate(nil)
            }
            .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 360)
    }
    
    private func login() {
        isLoggingIn = true
        errorMessage = nil
        
        GoogleAuthService.shared.startOAuthFlow { result in
            switch result {
            case .success:
                // スプシでメンバー確認
                self.verifyMembership()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoggingIn = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func verifyMembership() {
        guard let email = GoogleAuthService.shared.userEmail else {
            DispatchQueue.main.async {
                self.isLoggingIn = false
                self.errorMessage = "メールアドレスを取得できませんでした"
                GoogleAuthService.shared.logout()
            }
            return
        }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { result in
            DispatchQueue.main.async {
                self.isLoggingIn = false
                
                switch result {
                case .success:
                    // メンバー確認OK → ウィンドウを閉じる
                    if let window = NSApp.windows.first(where: { $0.title == "ログインが必要です" }) {
                        window.close()
                    }
                    
                    // Sparkleを開始
                    AppDelegate.shared?.startSparkleUpdater()
                    
                    // アクセシビリティ確認
                    if !HotkeyService.checkAccessibilityPermission() {
                        HotkeyService.requestAccessibilityPermission()
                    }
                    
                case .failure:
                    // メンバーリストにない → ログアウト
                    GoogleAuthService.shared.logout()
                    self.errorMessage = "メンバーリストに登録されていません。\n管理者に連絡してください。"
                }
            }
        }
    }
}
