//
//  DisplayTab.swift
//  SnipeeMac
//

import SwiftUI

struct DisplayTab: View {
    @State private var settings = StorageService.shared.getSettings()
    @State private var masterFolders: [SnippetFolder] = []
    @State private var personalFolders: [SnippetFolder] = []
    @State private var hiddenFolders: Set<String> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var allFolderNames: [String] {
        let masterNames = Set(masterFolders.map { $0.name })
        let personalNames = Set(personalFolders.map { $0.name })
        
        // マスタを上に、個別を下に
        let masterOnly = masterNames.subtracting(personalNames).sorted()
        let both = masterNames.intersection(personalNames).sorted()
        let personalOnly = personalNames.subtracting(masterNames).sorted()
        
        return masterOnly + both + personalOnly
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("📁 フォルダ表示設定")
                    .font(.headline)
                Text("表示したいフォルダにチェックを入れてください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Folder List
            if allFolderNames.isEmpty {
                Text("フォルダがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(allFolderNames, id: \.self) { folderName in
                            FolderCheckRow(
                                folderName: folderName,
                                isChecked: !hiddenFolders.contains(folderName),
                                isMaster: masterFolders.contains { $0.name == folderName },
                                isPersonal: personalFolders.contains { $0.name == folderName },
                                onToggle: { toggleFolder(folderName) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
            }
            
            // Buttons
            HStack(spacing: 8) {
                Button("全選択") {
                    selectAll()
                }
                .buttonStyle(.bordered)
                
                Button("全解除") {
                    deselectAll()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("💾 保存") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if showAlert {
                Text(alertMessage)
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            
            Spacer()
        }
        .onAppear {
            loadFolders()
        }
        .animation(.easeInOut(duration: 0.2), value: showAlert)
    }
    
    private func loadFolders() {
        masterFolders = StorageService.shared.getMasterSnippets()
        personalFolders = StorageService.shared.getPersonalSnippets()
        hiddenFolders = Set(settings.hiddenFolders)
    }
    
    private func toggleFolder(_ folderName: String) {
        if hiddenFolders.contains(folderName) {
            hiddenFolders.remove(folderName)
        } else {
            hiddenFolders.insert(folderName)
        }
    }
    
    private func selectAll() {
        hiddenFolders.removeAll()
    }
    
    private func deselectAll() {
        hiddenFolders = Set(allFolderNames)
    }
    
    private func saveSettings() {
        settings.hiddenFolders = Array(hiddenFolders)
        StorageService.shared.saveSettings(settings)
        
        alertMessage = "✅ フォルダ設定を保存しました（\(hiddenFolders.count)個のフォルダを非表示）"
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showAlert = false
        }
    }
}

// MARK: - Folder Check Row

struct FolderCheckRow: View {
    let folderName: String
    let isChecked: Bool
    let isMaster: Bool
    let isPersonal: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .accentColor : .secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            
            Text(folderName)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Spacer()
            
            // Badges
            if isMaster && isPersonal {
                BadgeView(text: "マスタ・個別", color: .blue)
            } else if isMaster {
                BadgeView(text: "マスタ", color: .green)
            } else if isPersonal {
                BadgeView(text: "個別", color: .orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }
}
