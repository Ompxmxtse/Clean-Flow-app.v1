import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - CSV Export Service
// Service for exporting cleaning logs and equipment data to CSV format

class CSVExportService {
    static let shared = CSVExportService()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private let fileNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()

    private init() {}

    // MARK: - Export Cleaning Logs

    func exportCleaningLogs(_ logs: [CleaningLog]) -> Result<URL, ExportError> {
        var csvContent = "ID,Equipment ID,Equipment Name,User ID,User Name,Cleaning Type,Completed At,Notes,Duration (seconds),Verified,Verified By,Verified At\n"

        for log in logs {
            let row = [
                escapeCSV(log.id),
                escapeCSV(log.equipmentId),
                escapeCSV(log.equipmentName),
                escapeCSV(log.userId),
                escapeCSV(log.userName),
                escapeCSV(log.cleaningType.rawValue),
                escapeCSV(dateFormatter.string(from: log.completedAt)),
                escapeCSV(log.notes ?? ""),
                escapeCSV(log.duration.map { String(Int($0)) } ?? ""),
                escapeCSV(log.verified ? "Yes" : "No"),
                escapeCSV(log.verifiedBy ?? ""),
                escapeCSV(log.verifiedAt.map { dateFormatter.string(from: $0) } ?? "")
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return saveToFile(content: csvContent, prefix: "cleaning_logs")
    }

    // MARK: - Export Cleaning Runs

    func exportCleaningRuns(_ runs: [CleaningRun]) -> Result<URL, ExportError> {
        var csvContent = "ID,Protocol ID,Protocol Name,Cleaner ID,Cleaner Name,Area ID,Area Name,Start Time,End Time,Status,Verification Method,Compliance Score,Notes\n"

        for run in runs {
            let row = [
                escapeCSV(run.id),
                escapeCSV(run.protocolId),
                escapeCSV(run.protocolName),
                escapeCSV(run.cleanerId),
                escapeCSV(run.cleanerName),
                escapeCSV(run.areaId),
                escapeCSV(run.areaName),
                escapeCSV(dateFormatter.string(from: run.startTime)),
                escapeCSV(run.endTime.map { dateFormatter.string(from: $0) } ?? ""),
                escapeCSV(run.status.rawValue),
                escapeCSV(run.verificationMethod.rawValue),
                escapeCSV(run.complianceScore.map { String(format: "%.1f", $0) } ?? ""),
                escapeCSV(run.notes ?? "")
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return saveToFile(content: csvContent, prefix: "cleaning_runs")
    }

    // MARK: - Export Equipment

    func exportEquipment(_ equipment: [Equipment]) -> Result<URL, ExportError> {
        var csvContent = "ID,Name,Description,Location,QR Code,Category,Status,Last Cleaned,Cleaning Interval (hours),Assigned To,Notes\n"

        for item in equipment {
            let row = [
                escapeCSV(item.id),
                escapeCSV(item.name),
                escapeCSV(item.description),
                escapeCSV(item.location),
                escapeCSV(item.qrCode),
                escapeCSV(item.category.rawValue),
                escapeCSV(item.status.rawValue),
                escapeCSV(item.lastCleaned.map { dateFormatter.string(from: $0) } ?? "Never"),
                escapeCSV(String(item.cleaningIntervalHours)),
                escapeCSV(item.assignedTo ?? ""),
                escapeCSV(item.notes ?? "")
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return saveToFile(content: csvContent, prefix: "equipment")
    }

    // MARK: - Export Users/Staff

    func exportUsers(_ users: [User]) -> Result<URL, ExportError> {
        var csvContent = "ID,Email,Name,Role,Department,Is Active,Created At,Last Login\n"

        for user in users {
            let row = [
                escapeCSV(user.id),
                escapeCSV(user.email),
                escapeCSV(user.name),
                escapeCSV(user.role.rawValue),
                escapeCSV(user.department),
                escapeCSV(user.isActive ? "Yes" : "No"),
                escapeCSV(dateFormatter.string(from: user.createdAt)),
                escapeCSV(dateFormatter.string(from: user.lastLogin))
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return saveToFile(content: csvContent, prefix: "users")
    }

    // MARK: - Export Protocols

    func exportProtocols(_ protocols: [CleaningProtocol]) -> Result<URL, ExportError> {
        var csvContent = "ID,Name,Description,Category,Estimated Time (seconds),Steps Count,Is Active,Created At\n"

        for proto in protocols {
            let row = [
                escapeCSV(proto.id),
                escapeCSV(proto.name),
                escapeCSV(proto.description),
                escapeCSV(proto.category),
                escapeCSV(String(Int(proto.estimatedTime))),
                escapeCSV(String(proto.steps.count)),
                escapeCSV(proto.isActive ? "Yes" : "No"),
                escapeCSV(dateFormatter.string(from: proto.createdAt))
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return saveToFile(content: csvContent, prefix: "protocols")
    }

    // MARK: - Export Compliance Report

    func exportComplianceReport(
        totalEquipment: Int,
        compliantCount: Int,
        dueSoonCount: Int,
        overdueCount: Int,
        cleaningLogs: [CleaningLog],
        dateRange: (start: Date, end: Date)? = nil
    ) -> Result<URL, ExportError> {
        let complianceRate = totalEquipment > 0 ? Double(compliantCount) / Double(totalEquipment) * 100 : 0

        var csvContent = "Clean-Flow Compliance Report\n"
        csvContent += "Generated:,\(dateFormatter.string(from: Date()))\n"

        if let range = dateRange {
            csvContent += "Date Range:,\(dateFormatter.string(from: range.start)) to \(dateFormatter.string(from: range.end))\n"
        }

        csvContent += "\n"
        csvContent += "Summary\n"
        csvContent += "Total Equipment:,\(totalEquipment)\n"
        csvContent += "Compliant:,\(compliantCount)\n"
        csvContent += "Due Soon:,\(dueSoonCount)\n"
        csvContent += "Overdue:,\(overdueCount)\n"
        csvContent += "Compliance Rate:,\(String(format: "%.1f%%", complianceRate))\n"
        csvContent += "\n"

        // Cleaning activity breakdown
        let cleaningsByType = Dictionary(grouping: cleaningLogs) { $0.cleaningType }
        csvContent += "Cleaning Activity by Type\n"
        csvContent += "Type,Count\n"
        for (type, logs) in cleaningsByType.sorted(by: { $0.value.count > $1.value.count }) {
            csvContent += "\(type.displayName),\(logs.count)\n"
        }
        csvContent += "\n"

        // Daily cleaning counts
        let dailyCounts = Dictionary(grouping: cleaningLogs) { log -> String in
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            return dateOnlyFormatter.string(from: log.completedAt)
        }

        csvContent += "Daily Cleaning Activity\n"
        csvContent += "Date,Count\n"
        for (date, logs) in dailyCounts.sorted(by: { $0.key > $1.key }) {
            csvContent += "\(date),\(logs.count)\n"
        }

        return saveToFile(content: csvContent, prefix: "compliance_report")
    }

    // MARK: - Private Helpers

    private func escapeCSV(_ string: String) -> String {
        var escaped = string
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private func saveToFile(content: String, prefix: String) -> Result<URL, ExportError> {
        let fileName = "\(prefix)_\(fileNameDateFormatter.string(from: Date())).csv"

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return .failure(.fileSystemError("Could not access documents directory"))
        }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            return .failure(.writeError(error))
        }
    }

    // MARK: - Share Sheet

    func shareCSV(from url: URL, in viewController: UIViewController) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        viewController.present(activityViewController, animated: true)
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case fileSystemError(String)
    case writeError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .writeError(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .noData:
            return "No data to export"
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Export to CSV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    @State private var showShareSheet = false
    @State private var exportedURL: URL?

    enum ExportResult {
        case success(URL)
        case failure(String)
    }

    var body: some View {
        NavigationView {
            List {
                Section("Export Data") {
                    ExportButton(title: "Cleaning Logs", icon: "doc.text.fill") {
                        exportCleaningLogs()
                    }

                    ExportButton(title: "Equipment Registry", icon: "list.bullet.rectangle.fill") {
                        exportEquipment()
                    }

                    ExportButton(title: "Staff/Users", icon: "person.2.fill") {
                        exportUsers()
                    }

                    ExportButton(title: "Protocols", icon: "list.clipboard.fill") {
                        exportProtocols()
                    }
                }

                Section("Reports") {
                    ExportButton(title: "Compliance Report", icon: "chart.bar.doc.horizontal.fill") {
                        exportComplianceReport()
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    ProgressView("Exporting...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .alert(item: Binding(
                get: { exportResult.map { AlertItem(result: $0) } },
                set: { _ in exportResult = nil }
            )) { item in
                switch item.result {
                case .success:
                    return Alert(
                        title: Text("Export Complete"),
                        message: Text("Your data has been exported successfully."),
                        primaryButton: .default(Text("Share")) {
                            showShareSheet = true
                        },
                        secondaryButton: .cancel()
                    )
                case .failure(let message):
                    return Alert(
                        title: Text("Export Failed"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func exportCleaningLogs() {
        isExporting = true
        DispatchQueue.global().async {
            let result = CSVExportService.shared.exportCleaningLogs(CleaningLog.mockData)
            DispatchQueue.main.async {
                isExporting = false
                handleExportResult(result)
            }
        }
    }

    private func exportEquipment() {
        isExporting = true
        DispatchQueue.global().async {
            let result = CSVExportService.shared.exportEquipment(Equipment.mockData)
            DispatchQueue.main.async {
                isExporting = false
                handleExportResult(result)
            }
        }
    }

    private func exportUsers() {
        isExporting = true
        DispatchQueue.global().async {
            let result = CSVExportService.shared.exportUsers([User.mock])
            DispatchQueue.main.async {
                isExporting = false
                handleExportResult(result)
            }
        }
    }

    private func exportProtocols() {
        isExporting = true
        DispatchQueue.global().async {
            let result = CSVExportService.shared.exportProtocols([CleaningProtocol.mock])
            DispatchQueue.main.async {
                isExporting = false
                handleExportResult(result)
            }
        }
    }

    private func exportComplianceReport() {
        isExporting = true
        DispatchQueue.global().async {
            let result = CSVExportService.shared.exportComplianceReport(
                totalEquipment: 5,
                compliantCount: 3,
                dueSoonCount: 1,
                overdueCount: 1,
                cleaningLogs: CleaningLog.mockData
            )
            DispatchQueue.main.async {
                isExporting = false
                handleExportResult(result)
            }
        }
    }

    private func handleExportResult(_ result: Result<URL, ExportError>) {
        switch result {
        case .success(let url):
            exportedURL = url
            exportResult = .success(url)
        case .failure(let error):
            exportResult = .failure(error.localizedDescription)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let result: ExportView.ExportResult
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
