// MARK: - Clean Flow Theme
import SwiftUI

struct CleanFlowTheme {
    
    // MARK: - Colors
    static let neonCyan = Color(red: 0/255, green: 255/255, blue: 255/255)
    static let neonBlue = Color(red: 0/255, green: 123/255, blue: 255/255)
    static let deepNavy = Color(red: 6/255, green: 10/255, blue: 25/255)
    static let background = LinearGradient(
        colors: [
            Color(red: 6/255, green: 10/255, blue: 25/255),
            Color(red: 11/255, green: 17/255, blue: 34/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [neonCyan, neonBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let textSecondary = Color.white.opacity(0.6)
    
    // MARK: - Card Colors
    static let card = Color.white.opacity(0.1)
    
    // MARK: - Status Colors
    static let successGreen = Color(red: 52/255, green: 211/255, blue: 153/255)
    static let warningYellow = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let errorRed = Color(red: 239/255, green: 68/255, blue: 68/255)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(CleanFlowTheme.accentGradient)
            .cornerRadius(16)
            .shadow(color: CleanFlowTheme.neonBlue.opacity(0.5), radius: 15)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(CleanFlowTheme.neonCyan)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(CleanFlowTheme.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CleanFlowTheme.neonCyan.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Text Field Components
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CleanFlowTheme.neonCyan)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(CleanFlowTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CleanFlowTheme.neonCyan.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CleanFlowTheme.neonCyan)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(CleanFlowTheme.textSecondary)
            }
        }
        .padding()
        .background(CleanFlowTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CleanFlowTheme.neonCyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Animated Background View
struct AnimatedBackgroundView: View {
    @State private var animate1 = false
    @State private var animate2 = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CleanFlowTheme.neonCyan.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate1 ? -50 : 50, y: animate1 ? -100 : 100)
                .blur(radius: 60)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CleanFlowTheme.neonBlue.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate2 ? 50 : -50, y: animate2 ? 100 : -100)
                .blur(radius: 60)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate1 = true
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate2 = true
            }
        }
    }
}
