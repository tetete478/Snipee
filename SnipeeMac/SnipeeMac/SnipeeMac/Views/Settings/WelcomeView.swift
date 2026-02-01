//
//  WelcomeView.swift
//  SnipeeMac
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentStep = 1
    @State private var userName = ""
    @State private var isLoggedIn = false
    @State private var loginError: String?
    @State private var isLoggingIn = false
    @Environment(\.dismiss) private var dismiss
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FF9500"), Color(hex: "FF6B00")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                stepIndicator
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                footerView
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
            .frame(width: 440, height: 480)
        }
        .frame(width: 500, height: 540)
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: "userName"), !saved.isEmpty {
                userName = saved
            }
            isLoggedIn = GoogleAuthService.shared.isLoggedIn
        }
        .background(KeyEventHandling(
            onEnter: { nextStep() },
            onEscape: { skipWizard() },
            onLeft: { prevStep() },
            onRight: { nextStep() }
        ))
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 2) {
            Text("📋")
                .font(.system(size: 28))
            Text("Snipee")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: "e5e5ea")),
            alignment: .bottom
        )
    }
    
    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == currentStep {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FF9500"))
                        .frame(width: 24, height: 8)
                } else if step < currentStep {
                    Circle()
                        .fill(Color(hex: "34c759"))
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color(hex: "d1d1d6"))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch currentStep {
                case 1: step1Welcome
                case 2: step2Login
                case 3: step3Name
                case 4: step4Hotkeys
                case 5: step5Complete
                default: EmptyView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 1: Welcome
    private var step1Welcome: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ようこそ！")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
            
            Text("Snipeeはクリップボード履歴とスニペットを管理するアプリです。\nチームで共有できるマスタスニペットと、個人用スニペットを使い分けられます。")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "86868b"))
                .lineSpacing(4)
            
            VStack(spacing: 12) {
                featureItem(icon: "📝", text: "クリップボード履歴を自動保存")
                featureItem(icon: "📁", text: "スニペットをフォルダで整理")
                featureItem(icon: "🔄", text: "Google Driveでチーム共有")
                featureItem(icon: "⌨️", text: "ホットキーで素早くアクセス")
            }
            .padding(.top, 16)
        }
    }
    
    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "1d1d1f"))
        }
    }
    
    // MARK: - Step 2: Login
    private var step2Login: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "FF9500"))
            
            Text("Googleでログイン")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
            
            Text("Snipeeを使用するには\n社内アカウントでログインが必要です")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "86868b"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            if isLoggedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("ログイン済み")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "1d1d1f"))
                }
                .padding(.top, 8)
            } else {
                Button(action: login) {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.key.fill")
                        }
                        Text(isLoggingIn ? "ログイン中..." : "Googleでログイン")
                    }
                    .frame(width: 200)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoggingIn)
                .padding(.top, 8)
                
                if let error = loginError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Step 3: Name Input
    private var step3Name: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("お名前を教えてください")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
            
            Text("スニペット内の {名前} 変数に使われます。\n後から設定画面で変更できます。")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "86868b"))
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("お名前（苗字推奨）")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1d1d1f"))
                
                TextField("例: 山田", text: $userName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "d1d1d6"), lineWidth: 1)
                    )
                
                Text("チーム内での表示に使われます")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "86868b"))
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Step 4: Hotkeys
    private var step4Hotkeys: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ホットキーを覚えましょう")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
            
            Text("いつでも素早くSnipeeを呼び出せます。")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "86868b"))
            
            VStack(spacing: 8) {
                hotkeyItem(
                    icon: "📋",
                    name: "クリップボード + スニペット",
                    desc: "履歴とスニペットを一覧表示",
                    keys: ["⌘", "⌃", "C"]
                )
                hotkeyItem(
                    icon: "📁",
                    name: "スニペット専用",
                    desc: "スニペットのみを表示",
                    keys: ["⌘", "⌃", "V"]
                )
                hotkeyItem(
                    icon: "🕐",
                    name: "履歴専用",
                    desc: "クリップボード履歴のみを表示",
                    keys: ["⌘", "⌃", "X"]
                )
            }
            .padding(.top, 8)
        }
    }
    
    private func hotkeyItem(icon: String, name: String, desc: String, keys: [String]) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1d1d1f"))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "86868b"))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "1d1d1f"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "d1d1d6"), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "f5f5f7"))
        .cornerRadius(8)
    }
    
    // MARK: - Step 5: Complete
    private var step5Complete: some View {
        VStack(spacing: 12) {
            Text("🎉")
                .font(.system(size: 36))
            
            Text("準備完了！")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1d1d1f"))
            
            Text("Snipeeの設定が完了しました。\n\nメニューバーのアイコンから設定を変更したり、\nホットキーでいつでも呼び出せます。")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "86868b"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            tipsBox
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var tipsBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("💡 Tips")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "FF9500"))
            
            HStack(spacing: 2) {
                Text("ウィンドウは")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "4a5568"))
                keyBadge("⌘")
                keyBadge("W")
                Text("または")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "4a5568"))
                keyBadge("Esc")
                Text("で閉じられます")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "4a5568"))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FFF4E6"))
        .overlay(
            Rectangle()
                .frame(width: 3)
                .foregroundColor(Color(hex: "FF9500")),
            alignment: .leading
        )
        .cornerRadius(8)
    }
    
    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(hex: "1d1d1f"))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: "d1d1d6"), lineWidth: 1)
            )
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            if currentStep < totalSteps && isLoggedIn {
                Button("スキップ") {
                    skipWizard()
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "86868b"))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if currentStep > 1 {
                    Button("戻る") {
                        prevStep()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Button(currentStep == totalSteps ? "Snipeeを始める" : "次へ") {
                    nextStep()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(hex: "fafafa"))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: "e5e5ea")),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    private func nextStep() {
        // ログインステップではログイン必須
        if currentStep == 2 && !isLoggedIn {
            return
        }
        
        if currentStep == 3 {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
        
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            completeWizard()
        }
    }
    
    private func prevStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private func skipWizard() {
        // ログインしてないとスキップ不可
        guard isLoggedIn else { return }
        completeWizard()
    }
    
    private func completeWizard() {
        UserDefaults.standard.set(true, forKey: "welcomeCompleted")
        
        // Sparkleを開始
        AppDelegate.shared?.startSparkleUpdater()
        
        dismiss()
        NSApplication.shared.keyWindow?.close()
    }
    
    private func login() {
        isLoggingIn = true
        loginError = nil
        
        GoogleAuthService.shared.startOAuthFlow { result in
            switch result {
            case .success:
                self.verifyMembership()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoggingIn = false
                    self.loginError = error.localizedDescription
                }
            }
        }
    }
    
    private func verifyMembership() {
        guard let email = GoogleAuthService.shared.userEmail else {
            DispatchQueue.main.async {
                self.isLoggingIn = false
                self.loginError = "メールアドレスを取得できませんでした"
                GoogleAuthService.shared.logout()
            }
            return
        }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { result in
            DispatchQueue.main.async {
                self.isLoggingIn = false
                
                switch result {
                case .success:
                    self.isLoggedIn = true
                case .failure:
                    GoogleAuthService.shared.logout()
                    self.loginError = "メンバーリストに登録されていません。\n管理者に連絡してください。"
                }
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? Color(hex: "E08600") : Color(hex: "FF9500"))
            .cornerRadius(8)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(configuration.isPressed ? Color(hex: "1d1d1f") : Color(hex: "86868b"))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? Color(hex: "f5f5f7") : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "d1d1d6"), lineWidth: 1)
            )
            .cornerRadius(8)
    }
}

// MARK: - Key Event Handling
struct KeyEventHandling: NSViewRepresentable {
    var onEnter: () -> Void
    var onEscape: () -> Void
    var onLeft: () -> Void
    var onRight: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onEnter = onEnter
        view.onEscape = onEscape
        view.onLeft = onLeft
        view.onRight = onRight
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class KeyView: NSView {
        var onEnter: (() -> Void)?
        var onEscape: (() -> Void)?
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 36: onEnter?()
            case 53: onEscape?()
            case 123: onLeft?()
            case 124: onRight?()
            default: super.keyDown(with: event)
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
