
//
//  ColorTheme.swift
//  SnipeeMac
//

import SwiftUI

enum ColorTheme: String, CaseIterable {
    case silver = "silver"
    case pearl = "pearl"
    case blush = "blush"
    case peach = "peach"
    case cream = "cream"
    case pistachio = "pistachio"
    case aqua = "aqua"
    case periwinkle = "periwinkle"
    case wisteria = "wisteria"
    
    var displayName: String {
        switch self {
        case .silver: return "シルバー"
        case .pearl: return "パール"
        case .blush: return "ブラッシュ"
        case .peach: return "ピーチ"
        case .cream: return "クリーム"
        case .pistachio: return "ピスタチオ"
        case .aqua: return "アクア"
        case .periwinkle: return "ペリウィンクル"
        case .wisteria: return "ウィステリア"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .silver: return Color(hex: "f5f5f7")
        case .pearl: return Color(hex: "f0eeeb")
        case .blush: return Color(hex: "fce8e8")
        case .peach: return Color(hex: "fde8d8")
        case .cream: return Color(hex: "fcf4d9")
        case .pistachio: return Color(hex: "e4f5e8")
        case .aqua: return Color(hex: "ddf2f5")
        case .periwinkle: return Color(hex: "e4e8fc")
        case .wisteria: return Color(hex: "ede4f5")
        }
    }
    
    var accentColor: Color {
        switch self {
        case .silver: return Color(hex: "86868b")
        case .pearl: return Color(hex: "a8a5a0")
        case .blush: return Color(hex: "c48888")
        case .peach: return Color(hex: "c89868")
        case .cream: return Color(hex: "b8a868")
        case .pistachio: return Color(hex: "70b080")
        case .aqua: return Color(hex: "58a8b8")
        case .periwinkle: return Color(hex: "7888c8")
        case .wisteria: return Color(hex: "9878b8")
        }
    }
    
    var textColor: Color {
        Color(hex: "1d1d1f")
    }
    
    var secondaryTextColor: Color {
        Color(hex: "86868b")
    }
    
    var hoverColor: Color {
        backgroundColor.opacity(0.8)
    }
    
    var selectedColor: Color {
        accentColor.opacity(0.2)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
