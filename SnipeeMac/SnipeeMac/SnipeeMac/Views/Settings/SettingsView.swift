
//
//  SettingsView.swift
//  SnipeeMac
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "一般"
    case display = "表示・操作"
    case account = "アカウント"
    case help = "ヘルプ"
    case admin = "管理者"
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.top, 8)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        GeneralTab()
                    case .display:
                        DisplayTab()
                    case .account:
                        AccountTab()
                    case .help:
                        HelpTab()
                    case .admin:
                        AdminTab()
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 450)
        .background(SettingsKeyHandler(
            onLeft: { selectPreviousTab() },
            onRight: { selectNextTab() },
            onEscape: { NSApplication.shared.keyWindow?.close() }
        ))
    }
    
    private func selectPreviousTab() {
        let allTabs = SettingsTab.allCases
        if let currentIndex = allTabs.firstIndex(of: selectedTab), currentIndex > 0 {
            selectedTab = allTabs[currentIndex - 1]
        }
    }
    
    private func selectNextTab() {
        let allTabs = SettingsTab.allCases
        if let currentIndex = allTabs.firstIndex(of: selectedTab), currentIndex < allTabs.count - 1 {
            selectedTab = allTabs[currentIndex + 1]
        }
    }
}

// MARK: - Key Event Handler
struct SettingsKeyHandler: NSViewRepresentable {
    var onLeft: () -> Void
    var onRight: () -> Void
    var onEscape: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = SettingsKeyView()
        view.onLeft = onLeft
        view.onRight = onRight
        view.onEscape = onEscape
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class SettingsKeyView: NSView {
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?
        var onEscape: (() -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 123: onLeft?()   // ←
            case 124: onRight?()  // →
            case 53: onEscape?()  // Esc
            default: super.keyDown(with: event)
            }
        }
    }
}

