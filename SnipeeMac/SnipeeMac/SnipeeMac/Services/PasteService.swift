
//
//  PasteService.swift
//  SnipeeMac
//

import AppKit

class PasteService {
    static let shared = PasteService()
    
    private var previousApp: NSRunningApplication?
    
    private init() {}
    
    func savePreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }
    
    func pasteText(_ text: String) {
        // Process variables
        let processedText = VariableService.shared.processVariables(text)
        
        // Write to clipboard
        ClipboardService.shared.writeToClipboard(processedText)
        
        // Return to previous app and paste
        let delay = StorageService.shared.getSettings().pasteDelay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
            self?.activatePreviousApp()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                self?.sendPasteCommand()
            }
        }
    }
    
    private func activatePreviousApp() {
        previousApp?.activate()
    }
    
    private func sendPasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down: Cmd + V
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
