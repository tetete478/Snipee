//
//  AppSettings.swift
//  SnipeeIOS
//

import Foundation

struct AppSettings: Codable {
    var lastSyncDate: Date?
    var autoSyncEnabled: Bool
    var syncIntervalMinutes: Int
    var dataExpiryDays: Int
    var sessionExpiryDays: Int
    var userName: String
    var onboardingCompleted: Bool
    var lastModifiedTime: String?

    static let `default` = AppSettings(
        lastSyncDate: nil,
        autoSyncEnabled: true,
        syncIntervalMinutes: 30,
        dataExpiryDays: 7,
        sessionExpiryDays: 30,
        userName: "",
        onboardingCompleted: false,
        lastModifiedTime: nil
    )

    init(
        lastSyncDate: Date? = nil,
        autoSyncEnabled: Bool = true,
        syncIntervalMinutes: Int = 30,
        dataExpiryDays: Int = 7,
        sessionExpiryDays: Int = 30,
        userName: String = "",
        onboardingCompleted: Bool = false,
        lastModifiedTime: String? = nil
    ) {
        self.lastSyncDate = lastSyncDate
        self.autoSyncEnabled = autoSyncEnabled
        self.syncIntervalMinutes = syncIntervalMinutes
        self.dataExpiryDays = dataExpiryDays
        self.sessionExpiryDays = sessionExpiryDays
        self.userName = userName
        self.onboardingCompleted = onboardingCompleted
        self.lastModifiedTime = lastModifiedTime
    }
}
