//
//  HotkeyField.swift
//  SnipeeMac
//

import SwiftUI
import Carbon

struct HotkeyField: View {
    let label: String
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt
    
    @State private var isRecording = false
    @State private var displayText = ""
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            
            Button(action: { isRecording.toggle() }) {
                Text(isRecording ? "入力待ち..." : displayText)
                    .frame(minWidth: 150)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            updateDisplayText()
        }
        .onChange(of: keyCode) {
            updateDisplayText()
        }
        .onChange(of: modifiers) {
            updateDisplayText()
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
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M"
        ]
        return keyMap[keyCode] ?? "?"
    }
}
