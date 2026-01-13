
//
//  SnippetEditorWindow.swift
//  SnipeeMac
//

import AppKit
import SwiftUI

class SnippetEditorWindow {
    static let shared = SnippetEditorWindow()
    
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        if window == nil {
            createWindow()
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
    
    private func createWindow() {
        let editorView = SnippetEditorView()
        let hostingController = NSHostingController(rootView: editorView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "スニペット編集"
        newWindow.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable, NSWindow.StyleMask.resizable, NSWindow.StyleMask.miniaturizable]
        newWindow.setContentSize(NSSize(width: 900, height: 600))
        newWindow.minSize = NSSize(width: 700, height: 400)
        newWindow.center()
        
        self.window = newWindow
    }
}
