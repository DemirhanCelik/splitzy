//
//  DesignSystem.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI

// MARK: - Colors
extension Color {
    struct Splitzy {
        // Light mode friendly colors
        static let background = Color(hex: 0xF5F7FA) // Light gray
        static let surface = Color.white
        
        // Vibrant accent colors
        static let vibrantPurple = Color(hex: 0x7C3AED) // More vivid purple
        static let electricTeal = Color(hex: 0x06B6D4)  // Cyan-ish teal
        
        // Dark theme (for future)
        static let deepDark = Color(hex: 0x1A1A2E)
        static let surfaceDark = Color(hex: 0x16213E)
        
        // Text
        static let textLight = Color(hex: 0xFDFDFD)
        static let textDark = Color(hex: 0x2C3A47)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let vibrantMain = LinearGradient(
        colors: [Color.Splitzy.vibrantPurple, Color.Splitzy.electricTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkSurface = LinearGradient(
        colors: [Color.Splitzy.surfaceDark, Color.Splitzy.deepDark],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glassOverlay = LinearGradient(
        colors: [.white.opacity(0.15), .white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Modifiers
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
//            .background(LinearGradient.glassOverlay) // Optional extra shine
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

struct PrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient.vibrantMain)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color.Splitzy.vibrantPurple.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
    
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButton())
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
