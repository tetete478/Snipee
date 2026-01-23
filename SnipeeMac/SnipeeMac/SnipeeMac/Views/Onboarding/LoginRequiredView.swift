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
            DispatchQueue.main.async {
                isLoggingIn = false
                switch result {
                case .success:
                    // ログイン成功 → ウィンドウを閉じる
                    NSApp.keyWindow?.close()
                    
                    // アクセシビリティ確認
                    if !HotkeyService.checkAccessibilityPermission() {
                        HotkeyService.requestAccessibilityPermission()
                    }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
