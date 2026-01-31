//
//  OnboardingWindow.swift
//  SnipeeMac
//

import AppKit
import SwiftUI

class OnboardingWindow {
    static let shared = OnboardingWindow()
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        if window != nil {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.close()
        })
        
        let hostingController = NSHostingController(rootView: onboardingView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.styleMask = [.borderless]
        newWindow.isMovableByWindowBackground = true
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.level = .floating
        newWindow.setContentSize(NSSize(width: 400, height: 300))
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        window = newWindow
    }
    
    func close() {
        window?.close()
        window = nil
    }
}

