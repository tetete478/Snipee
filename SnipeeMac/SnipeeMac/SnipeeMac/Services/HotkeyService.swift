
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
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        let hasCmd = flags.contains(.maskCommand)
        let hasCtrl = flags.contains(.maskControl)
        let hasAlt = flags.contains(.maskAlternate)
        
        // Cmd + Ctrl + C (keyCode 8)
        if keyCode == 8 && hasCmd && hasCtrl && !hasAlt {
            DispatchQueue.main.async { self.onMainHotkey?() }
            return nil
        }
        
        // Cmd + Ctrl + V (keyCode 9)
        if keyCode == 9 && hasCmd && hasCtrl && !hasAlt {
            DispatchQueue.main.async { self.onSnippetHotkey?() }
            return nil
        }
        
        // Cmd + Ctrl + X (keyCode 7)
        if keyCode == 7 && hasCmd && hasCtrl && !hasAlt {
            DispatchQueue.main.async { self.onHistoryHotkey?() }
            return nil
        }
        
        return Unmanaged.passRetained(event)
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
