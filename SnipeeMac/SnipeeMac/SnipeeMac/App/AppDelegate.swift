
//
//  AppDelegate.swift
//  SnipeeMac
//

import AppKit
import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    static var shared: AppDelegate?
    private var statusItem: NSStatusItem!
    private var clipboardService = ClipboardService.shared
    private var hotkeyService = HotkeyService.shared
    private var syncTimer: Timer?
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // 単一インスタンスチェック
        if let existingApp = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").first(where: { $0 != NSRunningApplication.current }) {
            existingApp.activate()
            NSApp.terminate(nil)
            return
        }
        
        // スコープ変更による強制再ログイン
        checkScopeVersionAndReloginIfNeeded()
        
        setupSparkle()
        setupStatusBar()
        setupHotkeys()
        startServices()
        setupAutoSync()
        
        // Show welcome wizard if not completed
        if !UserDefaults.standard.bool(forKey: "welcomeCompleted") {
            showWelcomeWindow()
        } else if !GoogleAuthService.shared.isLoggedIn {
            // 未ログインならログイン画面を強制表示
            showLoginRequiredWindow()
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
    
    private var settingsWindow: NSWindow?
    
    @objc private func openSettings() {
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "設定"
        newWindow.styleMask = [.titled, .closable]
        Constants.UI.configureModalWindow(newWindow)
        
        settingsWindow = newWindow
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Welcome Window
    
    private func showWelcomeWindow() {
        let welcomeView = WelcomeView()
        let hostingController = NSHostingController(rootView: welcomeView)
        
        let welcomeWindow = NSWindow(contentViewController: hostingController)
        welcomeWindow.title = "ようこそ - Snipee"
        welcomeWindow.styleMask = [.titled, .closable, .fullSizeContentView]
        welcomeWindow.backgroundColor = .clear
        Constants.UI.configureModalWindow(welcomeWindow)
    }
    
    // MARK: - Login Required Window
        
    private func showLoginRequiredWindow() {
        let loginView = LoginRequiredView()
        let hostingController = NSHostingController(rootView: loginView)
        
        let loginWindow = NSWindow(contentViewController: hostingController)
        loginWindow.title = "ログインが必要です"
        loginWindow.styleMask = [.titled, .fullSizeContentView]
        Constants.UI.configureModalWindow(loginWindow)
    }
    
    // MARK: - Hotkeys
    
    private func setupHotkeys() {
        hotkeyService.onMainHotkey = {
            guard GoogleAuthService.shared.isLoggedIn else { return }
            if NSApp.windows.contains(where: { $0.isVisible && $0 is NSPanel }) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .main)
                SyncService.shared.refreshMemberInfo()
            }
        }
        
        hotkeyService.onSnippetHotkey = {
            guard GoogleAuthService.shared.isLoggedIn else { return }
            if PopupWindowController.shared.isVisible(type: .snippet) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .snippet)
                SyncService.shared.refreshMemberInfo()
            }
        }

        hotkeyService.onHistoryHotkey = {
            guard GoogleAuthService.shared.isLoggedIn else { return }
            if PopupWindowController.shared.isVisible(type: .history) {
                PopupWindowController.shared.hidePopup()
            } else {
                PopupWindowController.shared.showPopup(type: .history)
                SyncService.shared.refreshMemberInfo()
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
                // ユーザーステータスをスプシに送信
                UserReportService.shared.reportUserStatus()
            case .failure(let error):
                print("Auto sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Scope Version Check
        
    private func checkScopeVersionAndReloginIfNeeded() {
        let currentScopeVersion = Constants.Google.scopeVersion
        let savedScopeVersion = UserDefaults.standard.integer(forKey: "scopeVersion")
        
        if savedScopeVersion < currentScopeVersion {
            // 古いスコープでログイン済みの場合は強制ログアウト
            if GoogleAuthService.shared.isLoggedIn {
                GoogleAuthService.shared.logout()
                print("スコープ変更のため再ログインが必要です")
            }
            // 新しいスコープバージョンを保存
            UserDefaults.standard.set(currentScopeVersion, forKey: "scopeVersion")
        }
    }
    
    
    // MARK: - Sparkle
    
    private func setupSparkle() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        
        // ログイン済みの場合のみUpdaterを開始
        if GoogleAuthService.shared.isLoggedIn {
            startSparkleUpdater()
        }
    }
    
    func startSparkleUpdater() {
        guard updaterController != nil else { return }
        guard !updaterController.updater.sessionInProgress else { return }
        
        do {
            try updaterController.updater.start()
            print("🔄 Sparkle started successfully")
        } catch {
            print("🔄 Sparkle start failed: \(error)")
        }
        
        print("🔄 feedURL: \(String(describing: updaterController.updater.feedURL))")
        
        // その日の初回起動時のみチェック
        checkForUpdatesIfNeeded()
    }
    
    private func checkForUpdatesIfNeeded() {
        // オンボーディング中（未ログイン）はスキップ
        guard GoogleAuthService.shared.isLoggedIn else {
            print("🔄 Not logged in, skipping update check")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastCheckKey = "lastUpdateCheckDate"
        
        if let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            let lastCheckDay = Calendar.current.startOfDay(for: lastCheck)
            if lastCheckDay >= today {
                print("🔄 Already checked today, skipping")
                return
            }
        }
        
        print("🔄 First launch today, checking for updates")
        UserDefaults.standard.set(Date(), forKey: lastCheckKey)
        
        // 少し遅延させてチェック（起動処理完了後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.updaterController.checkForUpdates(nil)
        }
    }
    
    // MARK: - SPUUpdaterDelegate
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        print("🔄 didFindValidUpdate: \(item.displayVersionString)")
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(
            name: .updateCheckCompleted,
            object: nil,
            userInfo: ["status": "新しいバージョン \(item.displayVersionString) があります"]
        )
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("🔄 updaterDidNotFindUpdate - already up to date")
        NotificationCenter.default.post(
            name: .updateCheckCompleted,
            object: nil,
            userInfo: ["status": "✓ 最新バージョンです"]
        )
    }
    
    func updater(_ updater: SPUUpdater, didFailToFindUpdateWithError error: Error) {
        print("🔄 didFailToFindUpdateWithError: \(error.localizedDescription)")
        NotificationCenter.default.post(
            name: .updateCheckCompleted,
            object: nil,
            userInfo: ["status": "エラー: \(error.localizedDescription)"]
        )
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("アップデート中断: \(error.localizedDescription)")
    }
    
    func checkForUpdates() {
        print("🔄 checkForUpdates called")
        updaterController.checkForUpdates(nil)
        print("🔄 checkForUpdates finished")
    }
}


extension Notification.Name {
    static let updateCheckCompleted = Notification.Name("updateCheckCompleted")
}
