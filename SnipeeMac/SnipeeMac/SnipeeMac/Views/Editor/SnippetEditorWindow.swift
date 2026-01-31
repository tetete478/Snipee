
//
//  SnippetEditorWindow.swift
//  SnipeeMac
//

import AppKit
import SwiftUI

class SnippetEditorWindow: NSObject, NSWindowDelegate {
    static let shared = SnippetEditorWindow()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
    
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
        newWindow.setContentSize(NSSize(width: 1100, height: 700))
        newWindow.minSize = NSSize(width: 900, height: 500)
        newWindow.center()
        newWindow.delegate = self
        
        self.window = newWindow
    }
}
