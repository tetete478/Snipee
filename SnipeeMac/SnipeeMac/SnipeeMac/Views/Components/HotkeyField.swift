//
//  HotkeyField.swift
//  SnipeeMac
//

import SwiftUI
import AppKit
import Carbon

struct HotkeyField: View {
    let label: String
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt
    
    @State private var isRecording = false
    @State private var displayText = ""
    @State private var monitor: Any?
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            
            Button(action: { toggleRecording() }) {
                Text(isRecording ? "入力待ち..." : displayText)
                    .frame(minWidth: 150)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            
            if isRecording {
                Button("キャンセル") {
                    stopRecording()
                }
                .font(.caption)
            }
        }
        .onAppear {
            updateDisplayText()
        }
        .onChange(of: keyCode) { _, _ in
            updateDisplayText()
        }
        .onChange(of: modifiers) { _, _ in
            updateDisplayText()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let newModifiers = event.modifierFlags.carbonFlags
            
            // 修飾キーのみは無視
            if event.keyCode == 55 || event.keyCode == 54 || // Cmd
               event.keyCode == 59 || event.keyCode == 62 || // Ctrl
               event.keyCode == 58 || event.keyCode == 61 || // Option
               event.keyCode == 56 || event.keyCode == 60 {  // Shift
                return nil
            }
            
            // 少なくとも1つの修飾キーが必要
            if newModifiers == 0 {
                return nil
            }
            
            keyCode = event.keyCode
            modifiers = UInt(newModifiers)
            
            stopRecording()
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func updateDisplayText() {
        var parts: [String] = []
        
        if modifiers & UInt(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt(controlKey) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt(shiftKey) != 0 {
            parts.append("⇧")
        }
        
        let keyString = keyCodeToString(keyCode)
        parts.append(keyString)
        
        displayText = parts.joined(separator: "")
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            // Letters
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
            // Numbers
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
            28: "8", 25: "9", 29: "0",
            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
            // Special keys
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "Esc",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
}

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}
