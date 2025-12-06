import SwiftUI
import AVFoundation

// MARK: - CleanFlowTextFieldStyle
// Custom text field style for auth views using ViewModifier pattern
struct CleanFlowTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

extension View {
    func cleanFlowTextField() -> some View {
        modifier(CleanFlowTextFieldStyle())
    }
}

// MARK: - CameraPreview
// Camera preview view for QR scanner
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession?

    init(session: AVCaptureSession? = nil) {
        self.session = session
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Impact Feedback Helper
func impactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

// MARK: - Trend Direction
enum TrendDirection {
    case up
    case down
    case neutral
}

// MARK: - StatCard
// Dashboard stat card component matching DashboardView usage
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var trend: TrendDirection? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(color)
                    )

                Spacer()

                if let trend = trend {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(trend == .up ? .green : .red)
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - DashboardStatCard
// Dashboard stat card with clear parameter labels
struct DashboardStatCard: View {
    let title: String
    let value: String
    let iconName: String
    let iconColor: Color
    let subtitle: String?

    init(title: String, value: String, iconName: String, iconColor: Color, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.iconColor = iconColor
        self.subtitle = subtitle
    }

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .padding(12)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)

                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - StepRowView
// Step row for protocol views
struct StepRowView: View {
    let step: CleaningStep
    var isCompleted: Bool = false
    var note: String? = nil
    var onAction: ((StepAction) -> Void)? = nil
    var protocolStep: CleaningStep? = nil

    init(step: CleaningStep, isCompleted: Bool = false, note: String? = nil, onAction: ((StepAction) -> Void)? = nil) {
        self.step = step
        self.isCompleted = isCompleted
        self.note = note
        self.onAction = onAction
        self.protocolStep = step
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Circle()
                .fill(isCompleted ? Color.green : Color.white.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: isCompleted ? "checkmark" : "")
                        .font(.caption)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(step.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                if !step.description.isEmpty {
                    Text(step.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                if let note = note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .italic()
                }
            }

            Spacer()

            Text("\(Int(step.duration / 60)) min")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onTapGesture {
            onAction?(.toggleComplete)
        }
    }
}
