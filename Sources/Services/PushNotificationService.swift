import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Push Notification Service
// Handles push notifications for cleaning reminders and compliance alerts

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private let notificationsEnabledKey = "pushNotificationsEnabled"
    private let overdueAlertsEnabledKey = "overdueAlertsEnabled"
    private let dueSoonAlertsEnabledKey = "dueSoonAlertsEnabled"
    private let dailySummaryEnabledKey = "dailySummaryEnabled"
    private let dailySummaryTimeKey = "dailySummaryTime"

    // Notification categories
    enum NotificationCategory: String {
        case cleaningDue = "CLEANING_DUE"
        case cleaningOverdue = "CLEANING_OVERDUE"
        case dailySummary = "DAILY_SUMMARY"
        case auditReminder = "AUDIT_REMINDER"
        case protocolUpdate = "PROTOCOL_UPDATE"
    }

    // Notification actions
    enum NotificationAction: String {
        case markComplete = "MARK_COMPLETE"
        case snooze = "SNOOZE"
        case viewDetails = "VIEW_DETAILS"
    }

    // MARK: - Settings

    var notificationsEnabled: Bool {
        get { userDefaults.bool(forKey: notificationsEnabledKey) }
        set { userDefaults.set(newValue, forKey: notificationsEnabledKey) }
    }

    var overdueAlertsEnabled: Bool {
        get { userDefaults.object(forKey: overdueAlertsEnabledKey) as? Bool ?? true }
        set { userDefaults.set(newValue, forKey: overdueAlertsEnabledKey) }
    }

    var dueSoonAlertsEnabled: Bool {
        get { userDefaults.object(forKey: dueSoonAlertsEnabledKey) as? Bool ?? true }
        set { userDefaults.set(newValue, forKey: dueSoonAlertsEnabledKey) }
    }

    var dailySummaryEnabled: Bool {
        get { userDefaults.object(forKey: dailySummaryEnabledKey) as? Bool ?? false }
        set { userDefaults.set(newValue, forKey: dailySummaryEnabledKey) }
    }

    var dailySummaryTime: Date {
        get {
            if let data = userDefaults.data(forKey: dailySummaryTimeKey),
               let date = try? JSONDecoder().decode(Date.self, from: data) {
                return date
            }
            // Default to 8:00 AM
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: dailySummaryTimeKey)
            }
        }
    }

    // MARK: - Initialization

    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        registerCategories()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
                self.notificationsEnabled = granted
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Register Categories

    private func registerCategories() {
        // Cleaning Due category with actions
        let markCompleteAction = UNNotificationAction(
            identifier: NotificationAction.markComplete.rawValue,
            title: "Mark Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Snooze 30 min",
            options: []
        )

        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationAction.viewDetails.rawValue,
            title: "View Details",
            options: [.foreground]
        )

        let cleaningDueCategory = UNNotificationCategory(
            identifier: NotificationCategory.cleaningDue.rawValue,
            actions: [markCompleteAction, snoozeAction, viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )

        let cleaningOverdueCategory = UNNotificationCategory(
            identifier: NotificationCategory.cleaningOverdue.rawValue,
            actions: [markCompleteAction, viewDetailsAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let dailySummaryCategory = UNNotificationCategory(
            identifier: NotificationCategory.dailySummary.rawValue,
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            cleaningDueCategory,
            cleaningOverdueCategory,
            dailySummaryCategory
        ])
    }

    // MARK: - Schedule Notifications

    func scheduleCleaningDueNotification(for equipment: Equipment, minutesBefore: Int = 30) {
        guard notificationsEnabled && dueSoonAlertsEnabled else { return }
        guard let nextDue = equipment.nextCleaningDue else { return }

        let triggerDate = nextDue.addingTimeInterval(-Double(minutesBefore * 60))

        // Don't schedule if already past
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cleaning Due Soon"
        content.body = "\(equipment.name) in \(equipment.location) needs cleaning in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.cleaningDue.rawValue
        content.userInfo = [
            "equipmentId": equipment.id,
            "equipmentName": equipment.name,
            "type": "due_soon"
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "cleaning-due-\(equipment.id)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling due notification: \(error)")
            }
        }
    }

    func scheduleOverdueNotification(for equipment: Equipment) {
        guard notificationsEnabled && overdueAlertsEnabled else { return }
        guard let nextDue = equipment.nextCleaningDue else { return }

        // Schedule for when it becomes overdue
        guard nextDue > Date() else {
            // Already overdue, send immediately
            sendImmediateOverdueNotification(for: equipment)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Cleaning Overdue"
        content.body = "\(equipment.name) in \(equipment.location) is now overdue for cleaning"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.cleaningOverdue.rawValue
        content.userInfo = [
            "equipmentId": equipment.id,
            "equipmentName": equipment.name,
            "type": "overdue"
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDue),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "cleaning-overdue-\(equipment.id)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling overdue notification: \(error)")
            }
        }
    }

    private func sendImmediateOverdueNotification(for equipment: Equipment) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Cleaning Overdue"
        content.body = "\(equipment.name) in \(equipment.location) is overdue for cleaning"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.cleaningOverdue.rawValue
        content.userInfo = [
            "equipmentId": equipment.id,
            "equipmentName": equipment.name,
            "type": "overdue"
        ]

        let request = UNNotificationRequest(
            identifier: "cleaning-overdue-immediate-\(equipment.id)",
            content: content,
            trigger: nil // Immediate delivery
        )

        notificationCenter.add(request)
    }

    func scheduleDailySummary(compliantCount: Int, dueSoonCount: Int, overdueCount: Int) {
        guard notificationsEnabled && dailySummaryEnabled else { return }

        // Remove existing daily summary
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily-summary"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Cleaning Summary"

        if overdueCount > 0 {
            content.body = "⚠️ \(overdueCount) overdue, \(dueSoonCount) due soon, \(compliantCount) compliant"
        } else if dueSoonCount > 0 {
            content.body = "\(dueSoonCount) items due soon, \(compliantCount) compliant"
        } else {
            content.body = "All \(compliantCount) items are compliant ✓"
        }

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.dailySummary.rawValue
        content.userInfo = ["type": "daily_summary"]

        // Get hour and minute from dailySummaryTime
        let components = Calendar.current.dateComponents([.hour, .minute], from: dailySummaryTime)

        var triggerComponents = DateComponents()
        triggerComponents.hour = components.hour
        triggerComponents.minute = components.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling daily summary: \(error)")
            }
        }
    }

    // MARK: - Cancel Notifications

    func cancelNotification(for equipmentId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "cleaning-due-\(equipmentId)",
            "cleaning-overdue-\(equipmentId)"
        ])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Get Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    func refreshPendingNotifications() {
        Task {
            let pending = await getPendingNotifications()
            await MainActor.run {
                self.pendingNotifications = pending
            }
        }
    }

    // MARK: - Update Badge

    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        updateBadge(count: 0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case NotificationAction.markComplete.rawValue:
            if let equipmentId = userInfo["equipmentId"] as? String {
                handleMarkComplete(equipmentId: equipmentId)
            }

        case NotificationAction.snooze.rawValue:
            if let equipmentId = userInfo["equipmentId"] as? String {
                handleSnooze(equipmentId: equipmentId)
            }

        case NotificationAction.viewDetails.rawValue, UNNotificationDefaultActionIdentifier:
            if let equipmentId = userInfo["equipmentId"] as? String {
                handleViewDetails(equipmentId: equipmentId)
            }

        default:
            break
        }

        completionHandler()
    }

    private func handleMarkComplete(equipmentId: String) {
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: .cleaningMarkedComplete,
            object: nil,
            userInfo: ["equipmentId": equipmentId]
        )
    }

    private func handleSnooze(equipmentId: String) {
        // Schedule a new notification for 30 minutes later
        let content = UNMutableNotificationContent()
        content.title = "Cleaning Reminder"
        content.body = "Snoozed cleaning is now due"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.cleaningDue.rawValue
        content.userInfo = ["equipmentId": equipmentId, "type": "snoozed"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)

        let request = UNNotificationRequest(
            identifier: "snooze-\(equipmentId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    private func handleViewDetails(equipmentId: String) {
        NotificationCenter.default.post(
            name: .viewEquipmentDetails,
            object: nil,
            userInfo: ["equipmentId": equipmentId]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cleaningMarkedComplete = Notification.Name("cleaningMarkedComplete")
    static let viewEquipmentDetails = Notification.Name("viewEquipmentDetails")
}

// MARK: - SwiftUI Settings View

import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var notificationService = PushNotificationService.shared
    @State private var showingTimePicker = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: Binding(
                    get: { notificationService.notificationsEnabled },
                    set: { newValue in
                        if newValue && !notificationService.isAuthorized {
                            Task {
                                await notificationService.requestAuthorization()
                            }
                        }
                        notificationService.notificationsEnabled = newValue
                    }
                ))
            } header: {
                Text("Notifications")
            } footer: {
                if !notificationService.isAuthorized {
                    Button("Open Settings to Enable") {
                        notificationService.openSettings()
                    }
                    .font(.caption)
                }
            }

            if notificationService.notificationsEnabled {
                Section("Alert Types") {
                    Toggle("Overdue Alerts", isOn: Binding(
                        get: { notificationService.overdueAlertsEnabled },
                        set: { notificationService.overdueAlertsEnabled = $0 }
                    ))

                    Toggle("Due Soon Alerts", isOn: Binding(
                        get: { notificationService.dueSoonAlertsEnabled },
                        set: { notificationService.dueSoonAlertsEnabled = $0 }
                    ))

                    Toggle("Daily Summary", isOn: Binding(
                        get: { notificationService.dailySummaryEnabled },
                        set: { notificationService.dailySummaryEnabled = $0 }
                    ))
                }

                if notificationService.dailySummaryEnabled {
                    Section("Daily Summary Time") {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { notificationService.dailySummaryTime },
                                set: { notificationService.dailySummaryTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section {
                    HStack {
                        Text("Pending Notifications")
                        Spacer()
                        Text("\(notificationService.pendingNotifications.count)")
                            .foregroundColor(.secondary)
                    }

                    Button("Clear All Notifications") {
                        notificationService.cancelAllNotifications()
                        notificationService.clearBadge()
                        notificationService.refreshPendingNotifications()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Notification Settings")
        .onAppear {
            notificationService.refreshPendingNotifications()
        }
    }
}
