//
//  BrightcoveTheme.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 31/03/26.
//


import SwiftUI

struct BCTheme {
    static let accent        = Color(hex: "#0070F3")
    static let accentLight   = Color(hex: "#3B8FF7")
    static let black         = Color(hex: "#0A0A0A")
    static let darkGray      = Color(hex: "#1A1A1A")
    static let cardGray      = Color(hex: "#242424")
    static let borderGray    = Color(hex: "#333333")
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "#A0A0A0")
    static let textTertiary  = Color(hex: "#606060")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct BCButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(BCTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct BCFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(BCTheme.cardGray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BCTheme.borderGray, lineWidth: 1)
            )
            .foregroundStyle(BCTheme.textPrimary)
            .tint(BCTheme.accent)
    }
}

extension View {
    func bcButton() -> some View { modifier(BCButtonStyle()) }
    func bcField() -> some View  { modifier(BCFieldStyle()) }
}
