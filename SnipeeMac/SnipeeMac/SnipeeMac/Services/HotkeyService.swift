//
//  HotkeyService.swift
//  SnipeeMac
//

import AppKit
import Carbon

class HotkeyService {
    static let shared = HotkeyService()
    
    private var mainHotkeyRef: EventHotKeyRef?
    private var snippetHotkeyRef: EventHotKeyRef?
    private var historyHotkeyRef: EventHotKeyRef?
    
    var onMainHotkey: (() -> Void)?
    var onSnippetHotkey: (() -> Void)?
    var onHistoryHotkey: (() -> Void)?
    
    private static let mainHotkeyID = UInt32(1)
    private static let snippetHotkeyID = UInt32(2)
    private static let historyHotkeyID = UInt32(3)
    
    private init() {
        setupEventHandler()
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                
                switch hotkeyID.id {
                case HotkeyService.mainHotkeyID:
                    DispatchQueue.main.async { HotkeyService.shared.onMainHotkey?() }
                case HotkeyService.snippetHotkeyID:
                    DispatchQueue.main.async { HotkeyService.shared.onSnippetHotkey?() }
                case HotkeyService.historyHotkeyID:
                    DispatchQueue.main.async { HotkeyService.shared.onHistoryHotkey?() }
                default:
                    break
                }
                
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
    
    func startListening() {
        let settings = StorageService.shared.getSettings()
        
        registerHotkey(
            config: settings.hotkeyMain,
            id: Self.mainHotkeyID,
            ref: &mainHotkeyRef
        )
        
        registerHotkey(
            config: settings.hotkeySnippet,
            id: Self.snippetHotkeyID,
            ref: &snippetHotkeyRef
        )
        
        registerHotkey(
            config: settings.hotkeyHistory,
            id: Self.historyHotkeyID,
            ref: &historyHotkeyRef
        )
    }
    
    func stopListening() {
        unregisterHotkey(&mainHotkeyRef)
        unregisterHotkey(&snippetHotkeyRef)
        unregisterHotkey(&historyHotkeyRef)
    }
    
    func reloadHotkeys() {
        stopListening()
        startListening()
    }
    
    private func registerHotkey(config: HotkeyConfig, id: UInt32, ref: inout EventHotKeyRef?) {
        var hotkeyID = EventHotKeyID(signature: OSType(0x534E5045), id: id) // 'SNPE'
        
        let carbonModifiers = carbonModifierFlags(from: config.modifiers)
        
        let status = RegisterEventHotKey(
            UInt32(config.keyCode),
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        if status != noErr {
            // Hotkey registration failed
        }
    }
    
    private func unregisterHotkey(_ ref: inout EventHotKeyRef?) {
        if let hotkeyRef = ref {
            UnregisterEventHotKey(hotkeyRef)
            ref = nil
        }
    }
    
    private func carbonModifierFlags(from modifiers: UInt) -> UInt32 {
        var carbonFlags: UInt32 = 0
        
        if modifiers & UInt(cmdKey) != 0 {
            carbonFlags |= UInt32(cmdKey)
        }
        if modifiers & UInt(controlKey) != 0 {
            carbonFlags |= UInt32(controlKey)
        }
        if modifiers & UInt(optionKey) != 0 {
            carbonFlags |= UInt32(optionKey)
        }
        if modifiers & UInt(shiftKey) != 0 {
            carbonFlags |= UInt32(shiftKey)
        }
        
        return carbonFlags
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
