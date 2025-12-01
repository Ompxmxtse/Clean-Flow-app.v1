// MARK: - App Entry Point with Launch Screen
import SwiftUI
import Firebase

@main
struct CleanFlowApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Launch Screen with Neon Logo Animation
struct LaunchScreenView: View {
    @State private var logoOpacity = 0.0
    @State private var glowIntensity = 0.0
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 6/255, green: 10/255, blue: 25/255),
                    Color(red: 11/255, green: 17/255, blue: 34/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated wave background
            WaveShape(offset: waveOffset)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0/255, green: 255/255, blue: 255/255).opacity(0.1),
                            Color(red: 0/255, green: 123/255, blue: 255/255).opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Neon Logo
                ZStack {
                    // Glow layers
                    Circle()
                        .fill(Color(red: 0/255, green: 255/255, blue: 255/255))
                        .frame(width: 140, height: 140)
                        .blur(radius: 40)
                        .opacity(glowIntensity * 0.6)
                    
                    Circle()
                        .fill(Color(red: 0/255, green: 123/255, blue: 255/255))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .opacity(glowIntensity * 0.4)
                    
                    // Logo - Stylized "C" wave
                    NeonCLogoView()
                        .frame(width: 100, height: 100)
                }
                .opacity(logoOpacity)
                
                Text("Clean-Flow")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0/255, green: 255/255, blue: 255/255), Color(red: 0/255, green: 123/255, blue: 255/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(logoOpacity)
                    .shadow(color: Color(red: 0/255, green: 255/255, blue: 255/255).opacity(0.5), radius: 12)
                
                Text("Medical Compliance System")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(logoOpacity * 0.8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                waveOffset = 400
            }
        }
    }
}

// MARK: - Neon C Logo Shape
struct NeonCLogoView: View {
    @State private var animateStroke = false
    
    var body: some View {
        ZStack {
            // Outer C
            CShape(thickness: 0.15)
                .trim(from: 0, to: animateStroke ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0/255, green: 255/255, blue: 255/255), Color(red: 0/255, green: 123/255, blue: 255/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .shadow(color: Color(red: 0/255, green: 255/255, blue: 255/255), radius: 8)
            
            // Inner wave detail
            CShape(thickness: 0.08)
                .trim(from: 0, to: animateStroke ? 1 : 0)
                .stroke(
                    Color(red: 0/255, green: 123/255, blue: 255/255).opacity(0.6),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .shadow(color: Color(red: 0/255, green: 123/255, blue: 255/255), radius: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animateStroke = true
            }
        }
    }
}

struct CShape: Shape {
    var thickness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * (1 - thickness)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(45),
            endAngle: .degrees(315),
            clockwise: false
        )
        return path
    }
}

// MARK: - Wave Shape for Background
struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.7))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset / width) * .pi * 4)
            let y = height * 0.7 + sine * 30
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}