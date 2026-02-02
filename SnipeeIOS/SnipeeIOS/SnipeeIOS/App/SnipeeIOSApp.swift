//
//  SnipeeIOSApp.swift
//  SnipeeIOS
//

import SwiftUI

@main
struct SnipeeIOSApp: App {
    @StateObject private var securityService = SecurityService.shared
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if securityService.isAuthenticated {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
            .onAppear {
                checkAuthStatus()
            }
        }
    }

    private func checkAuthStatus() {
        securityService.validateSession()
    }
}
