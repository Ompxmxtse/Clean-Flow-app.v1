import SwiftUI

// MARK: - ActivityHistoryView
// View showing full activity history for a staff member
struct ActivityHistoryView: View {
    let user: User
    @Environment(\.dismiss) var dismiss
    @State private var activities: [UserActivity] = UserActivity.mockActivities

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 6/255, green: 10/255, blue: 25/255),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activities) { activity in
                            ActivityHistoryRow(activity: activity)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
            }
        }
    }
}

// MARK: - ActivityHistoryRow
struct ActivityHistoryRow: View {
    let activity: UserActivity

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: activity.icon)
                    .font(.title3)
                    .foregroundColor(activity.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(activity.areaName)
                        .font(.caption)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))

                    Text(formatTime(activity.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ActivityHistoryView(user: User.mock)
}
