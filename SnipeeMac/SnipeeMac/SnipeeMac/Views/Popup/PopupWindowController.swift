//
//  PopupWindowController.swift
//  SnipeeMac
//

import AppKit
import SwiftUI

enum PopupType {
    case main
    case snippet
    case history
}

class PopupWindowController: NSObject {
    static let shared = PopupWindowController()
    
    private var window: NSPanel?
    private var currentType: PopupType = .main
    private var localMonitor: Any?
    
    var onKeyDown: ((UInt16) -> Bool)?
    
    private override init() {
        super.init()
    }
    
    func showPopup(type: PopupType) {
        currentType = type
        PasteService.shared.savePreviousApp()
        
        if window == nil {
            createWindow()
        }
        
        updateContent(type: type)
        positionWindow()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        startKeyboardMonitoring()
    }
    
    func hidePopup() {
        stopKeyboardMonitoring()
        window?.orderOut(nil)
    }

    func resizeWindow(width: CGFloat) {
        guard let window = window else { return }
        var frame = window.frame
        let oldWidth = frame.width
        frame.size.width = width
        frame.origin.x -= (width - oldWidth) / 2
        window.setFrame(frame, display: true, animate: false)
    }

    private func createWindow() {
            let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Constants.UI.popupWidth, height: Constants.UI.popupMaxHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
        
        self.window = panel
    }
    
    @objc private func windowDidResignKey() {
        hidePopup()
    }
    
    private func updateContent(type: PopupType) {
        let view: AnyView
        switch type {
        case .main:
            view = AnyView(MainPopupView())
        case .snippet:
            view = AnyView(SnippetPopupView())
        case .history:
            view = AnyView(HistoryPopupView())
        }
        
        let hostingView = NSHostingView(rootView: view)
        window?.contentView = hostingView
    }
    
    private func positionWindow() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        var windowFrame = window.frame
        
        windowFrame.origin.x = mouseLocation.x - windowFrame.width / 2
        windowFrame.origin.y = mouseLocation.y - windowFrame.height
        
        let screenFrame = screen.visibleFrame
        
        if windowFrame.maxX > screenFrame.maxX {
            windowFrame.origin.x = screenFrame.maxX - windowFrame.width
        }
        if windowFrame.minX < screenFrame.minX {
            windowFrame.origin.x = screenFrame.minX
        }
        if windowFrame.minY < screenFrame.minY {
            windowFrame.origin.y = screenFrame.minY
        }
        if windowFrame.maxY > screenFrame.maxY {
            windowFrame.origin.y = screenFrame.maxY - windowFrame.height
        }
        
        window.setFrame(windowFrame, display: true)
    }
    
    // MARK: - Keyboard Monitoring
    
    private func startKeyboardMonitoring() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // イベントを消費
            }
            return event
        }
    }
    
    private func stopKeyboardMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        
        switch keyCode {
        case 53: // Escape
            hidePopup()
            return true
        case 126: // Up arrow
            let _ = onKeyDown?(126)
            return true
        case 125: // Down arrow
            let _ = onKeyDown?(125)
            return true
        case 124: // Right arrow
            let _ = onKeyDown?(124)
            return true
        case 123: // Left arrow
            let _ = onKeyDown?(123)
            return true
        case 36: // Enter
            let _ = onKeyDown?(36)
            return true
        default:
            // Number keys 1-9
            if let chars = event.charactersIgnoringModifiers,
               let num = Int(chars), num >= 1 && num <= 9 {
                let _ = onKeyDown?(UInt16(num + 100)) // 101-109 for numbers
                return true
            }
            return false
        }
    }
}
