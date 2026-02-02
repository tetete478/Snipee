//
//  WelcomeView.swift
//  SnipeeIOS
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentStep = 0
    @State private var isLoggingIn = false
    @State private var loginError: String?
    @State private var userName = ""

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .tint(ColorTheme.primary)
                .padding()

            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                loginStep.tag(1)
                nameStep.tag(2)
                completeStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.primary)

            Text("Snipeeへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("スニペットを簡単にコピー&ペースト\nキーボードからも直接入力できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: { currentStep = 1 }) {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var loginStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.primary)

            Text("Googleでログイン")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("会社のGoogleアカウントで\nログインしてください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let error = loginError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: startLogin) {
                HStack {
                    if isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.crop.circle")
                        Text("Googleでログイン")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoggingIn)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.text.rectangle")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.primary)

            Text("お名前を入力")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("スニペットの変数置換で使用します")
                .font(.body)
                .foregroundColor(.secondary)

            TextField("お名前", text: $userName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: saveName) {
                Text("次へ")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userName.isEmpty ? Color.gray : ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(userName.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var completeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("準備完了!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("キーボード拡張を有効にすると\nどのアプリからでもスニペットを入力できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: completeOnboarding) {
                Text("始める")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Actions

    private func startLogin() {
        isLoggingIn = true
        loginError = nil

        Task {
            do {
                try await GoogleAuthService.shared.signIn()
                let isValid = await SecurityService.shared.validateMembership()
                if isValid {
                    currentStep = 2
                } else {
                    loginError = "メンバーとして登録されていません"
                    GoogleAuthService.shared.signOut()
                }
            } catch {
                loginError = "ログインに失敗しました"
            }
            isLoggingIn = false
        }
    }

    private func saveName() {
        var settings = StorageService.shared.getSettings()
        settings.userName = userName
        StorageService.shared.saveSettings(settings)
        currentStep = 3
    }

    private func completeOnboarding() {
        var settings = StorageService.shared.getSettings()
        settings.onboardingCompleted = true
        StorageService.shared.saveSettings(settings)
        SecurityService.shared.completeSetup()
    }
}

#Preview {
    WelcomeView()
}
