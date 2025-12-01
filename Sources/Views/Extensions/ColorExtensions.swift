import SwiftUI

extension Color {
    // Core brand colors
    static let deepNavy = Color(red: 0.024, green: 0.039, blue: 0.098) // #060A19
    static let neonAqua = Color(red: 0.169, green: 0.796, blue: 1.0) // #2BCBFF
    
    // Gradient colors
    static let bluePurpleStart = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let bluePurpleEnd = Color(red: 0.6, green: 0.4, blue: 1.0)
    
    // Status colors
    static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let errorRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    
    // Glass/Neumorphism colors
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.1)
    static let shadowLight = Color.black.opacity(0.3)
    static let shadowDark = Color.black.opacity(0.6)
    
    // Text colors
    static let primaryText = Color.white.opacity(0.9)
    static let secondaryText = Color.white.opacity(0.6)
    static let accentText = Color.neonAqua
}

// Gradient definitions
extension LinearGradient {
    static let bluePurple = LinearGradient(
        gradient: Gradient(colors: [.bluePurpleStart, .bluePurpleEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neonGlow = LinearGradient(
        gradient: Gradient(colors: [.neonAqua.opacity(0.8), .neonAqua.opacity(0.3)]),
        startPoint: .center,
        endPoint: .edges
    )
    
    static let glassEffect = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05),
            Color.white.opacity(0.02)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// Neumorphic view modifier
struct NeumorphicStyle: ViewModifier {
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: isPressed ? Color.shadowDark : Color.shadowLight,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 2 : -4,
                        y: isPressed ? 2 : -4
                    )
                    .shadow(
                        color: Color.white.opacity(0.1),
                        radius: 8,
                        x: 4,
                        y: 4
                    )
            )
    }
}

extension View {
    func neumorphic(isPressed: Bool = false) -> some View {
        modifier(NeumorphicStyle(isPressed: isPressed))
    }
    
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                            .blur(radius: 10)
                            .offset(x: 2, y: 2)
                    )
            )
    }
}
