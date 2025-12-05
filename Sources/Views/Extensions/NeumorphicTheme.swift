import SwiftUI

// MARK: - Neumorphic Design System
// Soft UI design system matching React Native implementation

struct NeumorphicTheme {
    // MARK: - Base Colors (Light Neumorphic)
    static let background = Color(hex: "E8ECEF")
    static let surfaceLight = Color(hex: "F5F7F9")
    static let surfaceDark = Color(hex: "D1D5D8")

    // MARK: - Accent Colors
    static let accent = Color(hex: "2563EB")         // Blue
    static let accentLight = Color(hex: "3B82F6")
    static let accentDark = Color(hex: "1D4ED8")

    // MARK: - Status Colors
    static let compliant = Color(hex: "10B981")      // Green
    static let dueSoon = Color(hex: "F59E0B")        // Orange
    static let overdue = Color(hex: "EF4444")        // Red

    // MARK: - Text Colors
    static let textPrimary = Color(hex: "1F2937")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")

    // MARK: - Shadow Colors
    static let shadowLight = Color.white.opacity(0.7)
    static let shadowDark = Color(hex: "A3B1C6").opacity(0.5)

    // MARK: - Corner Radii
    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 24

    // MARK: - Shadow Offsets
    static let shadowOffset: CGFloat = 6
    static let shadowRadius: CGFloat = 8
}

// MARK: - Color Extension for Hex Support
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Neumorphic View Modifiers

struct NeumorphicRaised: ViewModifier {
    var cornerRadius: CGFloat = NeumorphicTheme.radiusLarge

    func body(content: Content) -> some View {
        content
            .background(NeumorphicTheme.background)
            .cornerRadius(cornerRadius)
            .shadow(color: NeumorphicTheme.shadowLight, radius: NeumorphicTheme.shadowRadius, x: -NeumorphicTheme.shadowOffset, y: -NeumorphicTheme.shadowOffset)
            .shadow(color: NeumorphicTheme.shadowDark, radius: NeumorphicTheme.shadowRadius, x: NeumorphicTheme.shadowOffset, y: NeumorphicTheme.shadowOffset)
    }
}

struct NeumorphicInset: ViewModifier {
    var cornerRadius: CGFloat = NeumorphicTheme.radiusMedium

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NeumorphicTheme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(NeumorphicTheme.surfaceDark, lineWidth: 1)
                            .blur(radius: 1)
                            .offset(x: 1, y: 1)
                            .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(colors: [Color.black, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(NeumorphicTheme.surfaceLight, lineWidth: 1)
                            .blur(radius: 1)
                            .offset(x: -1, y: -1)
                            .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(colors: [Color.clear, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            )
    }
}

struct NeumorphicPressed: ViewModifier {
    var cornerRadius: CGFloat = NeumorphicTheme.radiusMedium

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NeumorphicTheme.background)
                    .shadow(color: NeumorphicTheme.shadowDark, radius: 4, x: 2, y: 2)
                    .shadow(color: NeumorphicTheme.shadowLight, radius: 4, x: -2, y: -2)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(NeumorphicTheme.surfaceDark.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    func neumorphicRaised(cornerRadius: CGFloat = NeumorphicTheme.radiusLarge) -> some View {
        modifier(NeumorphicRaised(cornerRadius: cornerRadius))
    }

    func neumorphicInset(cornerRadius: CGFloat = NeumorphicTheme.radiusMedium) -> some View {
        modifier(NeumorphicInset(cornerRadius: cornerRadius))
    }

    func neumorphicPressed(cornerRadius: CGFloat = NeumorphicTheme.radiusMedium) -> some View {
        modifier(NeumorphicPressed(cornerRadius: cornerRadius))
    }
}

// MARK: - Neumorphic Button Style

struct NeumorphicButtonStyle: ButtonStyle {
    var accentColor: Color = NeumorphicTheme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                            .fill(accentColor.opacity(0.9))
                            .shadow(color: NeumorphicTheme.shadowDark, radius: 2, x: 2, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                            .fill(accentColor)
                            .shadow(color: NeumorphicTheme.shadowLight, radius: NeumorphicTheme.shadowRadius, x: -NeumorphicTheme.shadowOffset, y: -NeumorphicTheme.shadowOffset)
                            .shadow(color: accentColor.opacity(0.4), radius: NeumorphicTheme.shadowRadius, x: NeumorphicTheme.shadowOffset, y: NeumorphicTheme.shadowOffset)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NeumorphicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(NeumorphicTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                            .fill(NeumorphicTheme.background)
                            .shadow(color: NeumorphicTheme.shadowDark, radius: 2, x: 2, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                            .fill(NeumorphicTheme.background)
                            .shadow(color: NeumorphicTheme.shadowLight, radius: NeumorphicTheme.shadowRadius, x: -NeumorphicTheme.shadowOffset, y: -NeumorphicTheme.shadowOffset)
                            .shadow(color: NeumorphicTheme.shadowDark, radius: NeumorphicTheme.shadowRadius, x: NeumorphicTheme.shadowOffset, y: NeumorphicTheme.shadowOffset)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Neumorphic Card View

struct NeumorphicCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = NeumorphicTheme.radiusLarge

    init(padding: CGFloat = 20, cornerRadius: CGFloat = NeumorphicTheme.radiusLarge, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(NeumorphicTheme.background)
            .cornerRadius(cornerRadius)
            .shadow(color: NeumorphicTheme.shadowLight, radius: NeumorphicTheme.shadowRadius, x: -NeumorphicTheme.shadowOffset, y: -NeumorphicTheme.shadowOffset)
            .shadow(color: NeumorphicTheme.shadowDark, radius: NeumorphicTheme.shadowRadius, x: NeumorphicTheme.shadowOffset, y: NeumorphicTheme.shadowOffset)
    }
}

// MARK: - Neumorphic Text Field

struct NeumorphicTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(NeumorphicTheme.accent)
                .frame(width: 24)

            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .foregroundColor(NeumorphicTheme.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(NeumorphicTheme.textPrimary)
            }

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(NeumorphicTheme.textTertiary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                .fill(NeumorphicTheme.background)
                .shadow(color: NeumorphicTheme.shadowDark.opacity(0.3), radius: 4, x: 2, y: 2)
                .shadow(color: NeumorphicTheme.shadowLight, radius: 4, x: -2, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NeumorphicTheme.radiusMedium)
                .stroke(NeumorphicTheme.surfaceDark.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Neumorphic Status Badge

struct NeumorphicStatusBadge: View {
    enum Status {
        case compliant
        case dueSoon
        case overdue

        var color: Color {
            switch self {
            case .compliant: return NeumorphicTheme.compliant
            case .dueSoon: return NeumorphicTheme.dueSoon
            case .overdue: return NeumorphicTheme.overdue
            }
        }

        var text: String {
            switch self {
            case .compliant: return "Compliant"
            case .dueSoon: return "Due Soon"
            case .overdue: return "Overdue"
            }
        }
    }

    let status: Status

    var body: some View {
        Text(status.text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(status.color)
                    .shadow(color: status.color.opacity(0.4), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - Neumorphic Progress Ring

struct NeumorphicProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var accentColor: Color = NeumorphicTheme.accent

    var body: some View {
        ZStack {
            // Background ring (inset effect)
            Circle()
                .stroke(NeumorphicTheme.surfaceDark.opacity(0.3), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 2)

            // Center value
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(NeumorphicTheme.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .neumorphicRaised(cornerRadius: size / 2)
        .padding(8)
    }
}

// MARK: - Neumorphic Icon Button

struct NeumorphicIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 50
    var iconColor: Color = NeumorphicTheme.accent

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .neumorphicRaised(cornerRadius: size / 2)
        }
    }
}

// MARK: - Preview

#Preview("Neumorphic Components") {
    ZStack {
        NeumorphicTheme.background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                Text("Neumorphic Design System")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(NeumorphicTheme.textPrimary)

                // Card
                NeumorphicCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sample Card")
                            .font(.headline)
                            .foregroundColor(NeumorphicTheme.textPrimary)
                        Text("This is a neumorphic card with soft shadows")
                            .font(.subheadline)
                            .foregroundColor(NeumorphicTheme.textSecondary)
                    }
                }

                // Text Field
                NeumorphicTextField(icon: "envelope", placeholder: "Email", text: .constant(""))

                // Buttons
                Button("Primary Button") {}
                    .buttonStyle(NeumorphicButtonStyle())

                Button("Secondary Button") {}
                    .buttonStyle(NeumorphicSecondaryButtonStyle())

                // Status Badges
                HStack(spacing: 12) {
                    NeumorphicStatusBadge(status: .compliant)
                    NeumorphicStatusBadge(status: .dueSoon)
                    NeumorphicStatusBadge(status: .overdue)
                }

                // Progress Ring
                NeumorphicProgressRing(progress: 0.75)

                // Icon Buttons
                HStack(spacing: 20) {
                    NeumorphicIconButton(icon: "qrcode", action: {})
                    NeumorphicIconButton(icon: "camera", action: {})
                    NeumorphicIconButton(icon: "bell", action: {})
                }
            }
            .padding(24)
        }
    }
}
