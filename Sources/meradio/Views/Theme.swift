import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Slate design tokens (Tailwind-inspired) for a clean, dark, sleek look.
enum Slate {
    static let s50  = Color(hex: 0xF8FAFC)
    static let s100 = Color(hex: 0xF1F5F9)
    static let s200 = Color(hex: 0xE2E8F0)
    static let s300 = Color(hex: 0xCBD5E1)
    static let s400 = Color(hex: 0x94A3B8)
    static let s500 = Color(hex: 0x64748B)
    static let s600 = Color(hex: 0x475569)
    static let s700 = Color(hex: 0x334155)
    static let s800 = Color(hex: 0x1E293B)
    static let s850 = Color(hex: 0x172033)
    static let s900 = Color(hex: 0x0F172A)
    static let s950 = Color(hex: 0x020617)

    /// Sky accent used sparingly for active / playing states.
    static let accent = Color(hex: 0x38BDF8)
    static let accentDim = Color(hex: 0x0EA5E9)

    static let textPrimary = s100
    static let textSecondary = s400
    static let textTertiary = s500

    /// App background gradient.
    static var background: LinearGradient {
        LinearGradient(
            colors: [s900, s950],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
