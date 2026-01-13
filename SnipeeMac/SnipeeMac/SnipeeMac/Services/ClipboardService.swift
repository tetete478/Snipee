
//
//  ClipboardService.swift
//  SnipeeMac
//

import AppKit
import Combine

class ClipboardService: ObservableObject {
    static let shared = ClipboardService()
    
    @Published var history: [HistoryItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    private init() {
        history = StorageService.shared.getHistory()
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else { return }
        
        let item = HistoryItem(content: content)
        addItem(item)
    }
    
    func addItem(_ item: HistoryItem) {
        // Remove duplicate
        history.removeAll { $0.content == item.content }
        // Add to beginning
        history.insert(item, at: 0)
        // Limit count
        let settings = StorageService.shared.getSettings()
        if history.count > settings.historyMaxCount {
            history = Array(history.prefix(settings.historyMaxCount))
        }
        // Save
        StorageService.shared.saveHistory(history)
    }
    
    func togglePin(for item: HistoryItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        history[index].isPinned.toggle()
        StorageService.shared.saveHistory(history)
    }
    
    func clearHistory() {
        history = history.filter { $0.isPinned }
        StorageService.shared.saveHistory(history)
    }
    
    func writeToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
}
