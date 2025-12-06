import SwiftUI

// MARK: - Theme Colors
private enum AuditTheme {
    static let neonAqua = Color(red: 43/255, green: 203/255, blue: 255/255)
    static let electricPurple = Color(red: 138/255, green: 77/255, blue: 255/255)
    static let errorRed = Color(red: 255/255, green: 100/255, blue: 100/255)
    static let warningAmber = Color(red: 255/255, green: 200/255, blue: 100/255)
    static let deepNavy = Color(red: 6/255, green: 10/255, blue: 25/255)
    static let glassFill = Color.white.opacity(0.1)
    static let glassStroke = Color.white.opacity(0.2)
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)
}

// MARK: - AuditListView
struct AuditListView: View {
    @StateObject private var viewModel = AuditListViewModel()
    @State private var selectedAudit: Audit?
    @State private var showingAuditDetail = false
    @State private var showingExportOptions = false
    @State private var selectedDateFilter: DateFilter = .all
    @State private var selectedUserFilter: String = ""
    @State private var selectedRoomFilter: String = ""
    @State private var searchText = ""

    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    var body: some View {
        let backgroundGradient = LinearGradient(
            colors: [AuditTheme.deepNavy, .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let contentView = VStack(spacing: 0) {
            filtersSection
            searchBar
            mainContent
        }

        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Audit Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { exportToolbarItem }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAuditDetail) { auditDetailSheet }
        .sheet(isPresented: $showingExportOptions) { exportSheet }
        .onAppear { viewModel.loadAudits() }
    }

    // MARK: - Private Subviews

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.filteredAudits.isEmpty {
            emptyStateView
        } else {
            auditList
        }
    }

    @ToolbarContentBuilder
    private var exportToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: { showingExportOptions = true }) {
                    Label("Export as CSV", systemImage: "doc.text")
                }
                Button(action: { /* Export as PDF */ }) {
                    Label("Export as PDF", systemImage: "doc.fill")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(AuditTheme.neonAqua)
            }
        }
    }

    @ViewBuilder
    private var auditDetailSheet: some View {
        if let audit = selectedAudit {
            AuditDetailView(audit: audit)
        }
    }

    private var exportSheet: some View {
        ExportOptionsView(
            audits: viewModel.filteredAudits,
            onExport: { format in
                viewModel.exportAudits(format: format)
                showingExportOptions = false
            }
        )
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: 12) {
            dateFilterChips
            dropdownFilters
        }
        .padding(.vertical, 12)
    }

    private var dateFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DateFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedDateFilter == filter
                    ) {
                        selectedDateFilter = filter
                        applyCurrentFilters()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var dropdownFilters: some View {
        HStack(spacing: 12) {
            userFilterDropdown
            roomFilterDropdown
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var userFilterDropdown: some View {
        DropdownFilterMenu(
            title: selectedUserFilter.isEmpty ? "All Users" : selectedUserFilter,
            options: viewModel.uniqueUsers,
            clearTitle: "All Users",
            onSelect: { user in
                selectedUserFilter = user
                applyCurrentFilters()
            },
            onClear: {
                selectedUserFilter = ""
                applyCurrentFilters()
            }
        )
    }

    private var roomFilterDropdown: some View {
        DropdownFilterMenu(
            title: selectedRoomFilter.isEmpty ? "All Rooms" : selectedRoomFilter,
            options: viewModel.uniqueRooms,
            clearTitle: "All Rooms",
            onSelect: { room in
                selectedRoomFilter = room
                applyCurrentFilters()
            },
            onClear: {
                selectedRoomFilter = ""
                applyCurrentFilters()
            }
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AuditTheme.textSecondary)

            TextField("Search audits...", text: $searchText)
                .foregroundColor(.white)
                .onChange(of: searchText) { _ in applyCurrentFilters() }

            if !searchText.isEmpty {
                clearSearchButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(searchBarBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var clearSearchButton: some View {
        Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(AuditTheme.textSecondary)
        }
    }

    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AuditTheme.glassFill)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AuditTheme.glassStroke, lineWidth: 1)
            )
    }

    // MARK: - Audit List

    private var auditList: some View {
        let audits = viewModel.filteredAudits

        return ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(audits) { audit in
                    AuditTimelineCard(audit: audit) {
                        selectedAudit = audit
                        showingAuditDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AuditTheme.neonAqua))
                .scaleEffect(1.5)

            Text("Loading audits...")
                .foregroundColor(AuditTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AuditTheme.textTertiary)

            Text("No Audits Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundColor(AuditTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Helper Methods

    private func applyCurrentFilters() {
        viewModel.applyFilters(
            dateFilter: selectedDateFilter,
            userFilter: selectedUserFilter,
            roomFilter: selectedRoomFilter,
            searchText: searchText
        )
    }
}

// MARK: - DropdownFilterMenu

private struct DropdownFilterMenu: View {
    let title: String
    let options: [String]
    let clearTitle: String
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
            Button(clearTitle) { onClear() }
        } label: {
            menuLabel
        }
    }

    private var menuLabel: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(AuditTheme.electricPurple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AuditTheme.glassFill)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AuditTheme.glassStroke, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let backgroundColor = isSelected ? AuditTheme.neonAqua : AuditTheme.glassFill
        let foregroundColor = isSelected ? AuditTheme.deepNavy : Color.white
        let strokeColor = isSelected ? Color.clear : AuditTheme.glassStroke

        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AuditTimelineCard

struct AuditTimelineCard: View {
    let audit: Audit
    let onTap: () -> Void

    var body: some View {
        let statusColor = self.statusColor
        let scoreColor = self.scoreColor

        Button(action: onTap) {
            HStack(spacing: 16) {
                timelineIndicator(color: statusColor)
                cardContent(statusColor: statusColor, scoreColor: scoreColor)
                Spacer()
            }
            .padding(16)
            .background(cardBackground)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Timeline Indicator

    private func timelineIndicator(color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2, height: 60)
        }
    }

    // MARK: - Card Content

    private func cardContent(statusColor: Color, scoreColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(statusColor: statusColor, scoreColor: scoreColor)
            cardDetails
        }
    }

    private func cardHeader(statusColor: Color, scoreColor: Color) -> some View {
        HStack {
            headerInfo
            Spacer()
            headerMetrics(statusColor: statusColor, scoreColor: scoreColor)
        }
    }

    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Audit #\(String(audit.id.suffix(6)))")
                .font(.headline)
                .foregroundColor(.white)

            Text(formatDate(audit.createdAt))
                .font(.caption)
                .foregroundColor(AuditTheme.textSecondary)
        }
    }

    private func headerMetrics(statusColor: Color, scoreColor: Color) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(audit.complianceScore))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)

            statusBadge(color: statusColor)
        }
    }

    private func statusBadge(color: Color) -> some View {
        Text(audit.status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    // MARK: - Card Details

    private var cardDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow(icon: "person.fill", text: audit.auditorName)
            detailRow(icon: "building.2.fill", text: audit.roomName)

            if audit.hasExceptions {
                exceptionsRow
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AuditTheme.neonAqua)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }

    private var exceptionsRow: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(AuditTheme.errorRed)

            Text("\(audit.exceptionCount) exceptions")
                .font(.caption)
                .foregroundColor(AuditTheme.errorRed)
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        let gradientStroke = LinearGradient(
            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gradientStroke, lineWidth: 1)
            )
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch audit.status {
        case .completed: return AuditTheme.neonAqua
        case .inProgress: return AuditTheme.electricPurple
        case .failed: return AuditTheme.errorRed
        case .pending: return AuditTheme.textSecondary
        }
    }

    private var scoreColor: Color {
        switch audit.complianceScore {
        case 90...: return AuditTheme.neonAqua
        case 75..<90: return AuditTheme.warningAmber
        default: return AuditTheme.errorRed
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ExportOptionsView

struct ExportOptionsView: View {
    let audits: [Audit]
    let onExport: (ExportFormat) -> Void

    enum ExportFormat {
        case csv
        case pdf
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        let backgroundGradient = LinearGradient(
            colors: [AuditTheme.deepNavy, .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AuditTheme.neonAqua)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var contentView: some View {
        VStack(spacing: 24) {
            headerSection
            exportOptions
            Spacer()
        }
        .padding()
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(AuditTheme.neonAqua)

            Text("Export Audit Log")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Choose export format for \(audits.count) audits")
                .font(.subheadline)
                .foregroundColor(AuditTheme.textSecondary)
        }
        .padding(.top, 40)
    }

    private var exportOptions: some View {
        VStack(spacing: 16) {
            ExportOptionCard(
                title: "CSV Format",
                description: "Spreadsheet-compatible format with all audit data",
                icon: "doc.text",
                color: AuditTheme.neonAqua
            ) {
                onExport(.csv)
            }

            ExportOptionCard(
                title: "PDF Format",
                description: "Formatted report suitable for printing and sharing",
                icon: "doc.fill",
                color: AuditTheme.electricPurple
            ) {
                onExport(.pdf)
            }
        }
    }
}

// MARK: - ExportOptionCard

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                iconView
                textContent
                Spacer()
                chevron
            }
            .padding(16)
            .background(cardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundColor(color)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.2))
            .clipShape(Circle())
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(description)
                .font(.caption)
                .foregroundColor(AuditTheme.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(AuditTheme.textTertiary)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AuditTheme.glassFill, lineWidth: 1)
            )
    }
}

#Preview {
    AuditListView()
}
