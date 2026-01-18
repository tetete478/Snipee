
//
//  AppDelegate.swift
//  SnipeeMac
//

import AppKit
import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var clipboardService = ClipboardService.shared
    private var hotkeyService = HotkeyService.shared
    private var syncTimer: Timer?
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 単一インスタンスチェック
        if let existingApp = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").first(where: { $0 != NSRunningApplication.current }) {
            existingApp.activate(options: [.activateIgnoringOtherApps])
            NSApp.terminate(nil)
            return
        }
        
        setupSparkle()
        setupStatusBar()
        setupHotkeys()
        startServices()
        setupAutoSync()
        
        // Show onboarding if not completed
        let settings = StorageService.shared.getSettings()
        if !settings.onboardingCompleted {
            OnboardingWindow.shared.show()
        } else {
            // Check accessibility permission
            if !HotkeyService.checkAccessibilityPermission() {
                HotkeyService.requestAccessibilityPermission()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.stopListening()
        clipboardService.stopMonitoring()
        syncTimer?.invalidate()
    }
    
    
    // MARK: - URL Handling

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.scheme == "com.addness.snipeemac" else {
            return
        }
        
        GoogleAuthService.shared.handleCallback(url: url)
    }
    
    
    // MARK: - Status Bar
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Snipee")
            button.action = #selector(statusBarClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupStatusBarMenu()
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "履歴を開く", action: #selector(openHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "スニペットを開く", action: #selector(openSnippets), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Snipeeを終了", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show menu (handled automatically)
        } else {
            // Left click - show main popup
            statusItem.menu = nil
            PopupWindowController.shared.showPopup(type: .main)
            
            // Re-enable menu for next right-click
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.setupStatusBarMenu()
            }
        }
    }
    
    // MARK: - Menu Actions
    
    @objc private func openHistory() {
        PopupWindowController.shared.showPopup(type: .history)
    }
    
    @objc private func openSnippets() {
        PopupWindowController.shared.showPopup(type: .snippet)
    }
    
    @objc private func openSettings() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let settingsWindow = NSWindow(contentViewController: hostingController)
        settingsWindow.title = "設定"
        settingsWindow.styleMask = [.titled, .closable]
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Hotkeys
    
    private func setupHotkeys() {
        hotkeyService.onMainHotkey = {
            if NSApp.windows.contains(where: { $0.isVisible && $0 is NSPanel }) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .main)
            }
        }
        
        hotkeyService.onSnippetHotkey = {
            if PopupWindowController.shared.isVisible(type: .snippet) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .snippet)
            }
        }

        hotkeyService.onHistoryHotkey = {
            if PopupWindowController.shared.isVisible(type: .history) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .history)
            }
        }
        
        hotkeyService.startListening()
    }
    
    // MARK: - Services
    
    private func startServices() {
        clipboardService.startMonitoring()
    }
    
    // MARK: - Auto Sync

    private func setupAutoSync() {
        // Sync on launch if logged in
        if GoogleAuthService.shared.isLoggedIn {
            performSync()
        }
        
        // Setup hourly sync timer
        syncTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.performSync()
        }
    }

    private func performSync() {
        guard GoogleAuthService.shared.isLoggedIn else { return }
        
        SyncService.shared.syncMasterSnippets { result in
            switch result {
            case .success(let syncResult):
                print("Auto sync success: \(syncResult.folderCount) folders, \(syncResult.snippetCount) snippets")
            case .failure(let error):
                print("Auto sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sparkle
    
    private func setupSparkle() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
