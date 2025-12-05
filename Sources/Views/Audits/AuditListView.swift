import SwiftUI

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
                
                VStack(spacing: 0) {
                    // Filters Section
                    filtersSection
                    
                    // Search Bar
                    searchBar
                    
                    // Audit List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredAudits.isEmpty {
                        emptyStateView
                    } else {
                        auditList
                    }
                }
            }
            .navigationTitle("Audit Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Label("Export as CSV", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            // Export as PDF
                        }) {
                            Label("Export as PDF", systemImage: "doc.fill")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAuditDetail) {
            if let audit = selectedAudit {
                AuditDetailView(audit: audit)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                audits: viewModel.filteredAudits,
                onExport: { format in
                    viewModel.exportAudits(format: format)
                    showingExportOptions = false
                }
            )
        }
        .onAppear {
            viewModel.loadAudits()
        }
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Date Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedDateFilter == filter
                        ) {
                            selectedDateFilter = filter
                            viewModel.applyFilters(
                                dateFilter: selectedDateFilter,
                                userFilter: selectedUserFilter,
                                roomFilter: selectedRoomFilter,
                                searchText: searchText
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // User & Room Filters
            HStack(spacing: 12) {
                Menu {
                    ForEach(viewModel.uniqueUsers, id: \.self) { user in
                        Button(user) {
                            selectedUserFilter = user
                            viewModel.applyFilters(
                                dateFilter: selectedDateFilter,
                                userFilter: selectedUserFilter,
                                roomFilter: selectedRoomFilter,
                                searchText: searchText
                            )
                        }
                    }
                    
                    Button("All Users") {
                        selectedUserFilter = ""
                        viewModel.applyFilters(
                            dateFilter: selectedDateFilter,
                            userFilter: selectedUserFilter,
                            roomFilter: selectedRoomFilter,
                            searchText: searchText
                        )
                    }
                } label: {
                    HStack {
                        Text(selectedUserFilter.isEmpty ? "All Users" : selectedUserFilter)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color(red: 138/255, green: 77/255, blue: 255/255))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(20)
                }
                
                Menu {
                    ForEach(viewModel.uniqueRooms, id: \.self) { room in
                        Button(room) {
                            selectedRoomFilter = room
                            viewModel.applyFilters(
                                dateFilter: selectedDateFilter,
                                userFilter: selectedUserFilter,
                                roomFilter: selectedRoomFilter,
                                searchText: searchText
                            )
                        }
                    }
                    
                    Button("All Rooms") {
                        selectedRoomFilter = ""
                        viewModel.applyFilters(
                            dateFilter: selectedDateFilter,
                            userFilter: selectedUserFilter,
                            roomFilter: selectedRoomFilter,
                            searchText: searchText
                        )
                    }
                } label: {
                    HStack {
                        Text(selectedRoomFilter.isEmpty ? "All Rooms" : selectedRoomFilter)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color(red: 138/255, green: 77/255, blue: 255/255))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(20)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.white.opacity(0.6))
            
            TextField("Search audits...", text: $searchText)
                .foregroundColor(.white)
                .onChange(of: searchText) { newValue in
                    viewModel.applyFilters(
                        dateFilter: selectedDateFilter,
                        userFilter: selectedUserFilter,
                        roomFilter: selectedRoomFilter,
                        searchText: newValue
                    )
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Audit List
    private var auditList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAudits) { audit in
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
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 43/255, green: 203/255, blue: 255/255)))
                .scaleEffect(1.5)
            
            Text("Loading audits...")
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color.white.opacity(0.4))
            
            Text("No Audits Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Audit Timeline Card
struct AuditTimelineCard: View {
    let audit: Audit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Timeline Indicator
                VStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 2, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audit #\(String(audit.id.suffix(6)))")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(formatDate(audit.createdAt))
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(audit.complianceScore))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor)
                            
                            statusBadge
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                            
                            Text(audit.auditorName)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "building.2.fill")
                                .font(.caption)
                                .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                            
                            Text(audit.roomName)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        if audit.hasExceptions {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                                
                                Text("\(audit.exceptionCount) exceptions")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch audit.status {
        case .completed: return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .inProgress: return Color(red: 138/255, green: 77/255, blue: 255/255)
        case .failed: return Color(red: 255/255, green: 100/255, blue: 100/255)
        case .pending: return Color.white.opacity(0.6)
        }
    }
    
    private var scoreColor: Color {
        if audit.complianceScore >= 90 {
            return Color(red: 43/255, green: 203/255, blue: 255/255)
        } else if audit.complianceScore >= 75 {
            return Color(red: 255/255, green: 200/255, blue: 100/255)
        } else {
            return Color(red: 255/255, green: 100/255, blue: 100/255)
        }
    }
    
    private var statusBadge: some View {
        Text(audit.status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color(red: 43/255, green: 203/255, blue: 255/255) : Color.white.opacity(0.1)
                )
                .foregroundColor(
                    isSelected ? Color(red: 6/255, green: 10/255, blue: 25/255) : .white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    let audits: [Audit]
    let onExport: (ExportFormat) -> Void
    
    enum ExportFormat {
        case csv
        case pdf
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 6/255, green: 10/255, blue: 25/255),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        
                        Text("Export Audit Log")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Choose export format for \(audits.count) audits")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .padding(.top, 40)
                    
                    // Export Options
                    VStack(spacing: 16) {
                        ExportOptionCard(
                            title: "CSV Format",
                            description: "Spreadsheet-compatible format with all audit data",
                            icon: "doc.text",
                            color: Color(red: 43/255, green: 203/255, blue: 255/255)
                        ) {
                            onExport(.csv)
                        }
                        
                        ExportOptionCard(
                            title: "PDF Format",
                            description: "Formatted report suitable for printing and sharing",
                            icon: "doc.fill",
                            color: Color(red: 138/255, green: 77/255, blue: 255/255)
                        ) {
                            onExport(.pdf)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AuditListView()
}
