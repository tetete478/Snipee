
//
//  HotkeyService.swift
//  SnipeeMac
//

import AppKit
import Carbon

class HotkeyService {
    static let shared = HotkeyService()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onMainHotkey: (() -> Void)?
    var onSnippetHotkey: (() -> Void)?
    var onHistoryHotkey: (() -> Void)?
    
    private init() {}
    
    func startListening() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap. Check accessibility permissions.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stopListening() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        let settings = StorageService.shared.getSettings()
        
        // Main hotkey
        if matchesHotkey(keyCode: keyCode, flags: flags, config: settings.hotkeyMain) {
            DispatchQueue.main.async { self.onMainHotkey?() }
            return nil
        }
        
        // Snippet hotkey
        if matchesHotkey(keyCode: keyCode, flags: flags, config: settings.hotkeySnippet) {
            DispatchQueue.main.async { self.onSnippetHotkey?() }
            return nil
        }
        
        // History hotkey
        if matchesHotkey(keyCode: keyCode, flags: flags, config: settings.hotkeyHistory) {
            DispatchQueue.main.async { self.onHistoryHotkey?() }
            return nil
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func matchesHotkey(keyCode: UInt16, flags: CGEventFlags, config: HotkeyConfig) -> Bool {
        guard keyCode == config.keyCode else { return false }
        
        let hasCmd = flags.contains(.maskCommand)
        let hasCtrl = flags.contains(.maskControl)
        let hasAlt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        
        let configHasCmd = config.modifiers & UInt(cmdKey) != 0
        let configHasCtrl = config.modifiers & UInt(controlKey) != 0
        let configHasAlt = config.modifiers & UInt(optionKey) != 0
        let configHasShift = config.modifiers & UInt(shiftKey) != 0
        
        return hasCmd == configHasCmd &&
               hasCtrl == configHasCtrl &&
               hasAlt == configHasAlt &&
               hasShift == configHasShift
    }
    
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
