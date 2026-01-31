//
//  UserStatus.swift
//  SnipeeMac
//

import Foundation

struct UserStatus: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let department: String
    let role: String
    let version: String
    let lastActive: String
    let snippetCount: String
    
    var isOutdated: Bool {
        guard !version.isEmpty else { return false }
        let currentVersion = Constants.App.version
        return version != currentVersion
    }
    
    var isInactive: Bool {
        guard !lastActive.isEmpty else { return true }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let lastDate = formatter.date(from: lastActive) else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince > 7
    }
}
