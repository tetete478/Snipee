//
//  HistoryItem.swift
//  SnipeeMac
//

import Foundation

struct HistoryItem: Codable, Identifiable {
    let id: String
    var content: String
    var timestamp: Date
    var isPinned: Bool
    
    init(id: String = UUID().uuidString, content: String, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }
}
