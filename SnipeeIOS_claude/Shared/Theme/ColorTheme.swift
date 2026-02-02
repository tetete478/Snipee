//
//  ColorTheme.swift
//  SnipeeIOS
//

import SwiftUI

struct ColorTheme {
    // Primary brand color - Orange
    static let primary = Color(red: 255/255, green: 107/255, blue: 53/255) // #FF6B35

    // Secondary colors
    static let secondary = Color(red: 255/255, green: 140/255, blue: 90/255)
    static let accent = Color(red: 255/255, green: 180/255, blue: 140/255)

    // Background colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)

    // Text colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // Gradient
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
