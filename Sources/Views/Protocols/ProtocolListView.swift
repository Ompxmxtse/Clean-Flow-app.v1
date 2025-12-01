import SwiftUI

struct ProtocolListView: View {
    @StateObject private var viewModel = ProtocolListViewModel()
    @State private var selectedProtocol: CleaningProtocol?
    @State private var showingProtocolDetail = false
    @State private var searchText = ""
    @State private var selectedArea: CleaningProtocol.AreaType?
    
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
                    // Search and Filters
                    searchAndFilters
                    
                    // Protocol List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredProtocols.isEmpty {
                        emptyStateView
                    } else {
                        protocolList
                    }
                }
            }
            .navigationTitle("Protocols")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Create new protocol
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingProtocolDetail) {
            if let protocol = selectedProtocol {
                ProtocolDetailView(protocol: protocol)
            }
        }
        .onAppear {
            viewModel.loadProtocols()
        }
    }
    
    // MARK: - Search and Filters
    private var searchAndFilters: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.6))
                
                TextField("Search protocols...", text: $searchText)
                    .foregroundColor(.white)
                    .onChange(of: searchText) { newValue in
                        viewModel.applyFilters(areaType: selectedArea, searchText: newValue)
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
            
            // Area Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All Areas option
                    AreaFilterChip(
                        title: "All Areas",
                        isSelected: selectedArea == nil
                    ) {
                        selectedArea = nil
                        viewModel.applyFilters(areaType: nil, searchText: searchText)
                    }
                    
                    // Actual area types from model
                    ForEach(CleaningProtocol.AreaType.allCases, id: \.self) { area in
                        AreaFilterChip(
                            title: area.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                            isSelected: selectedArea == area
                        ) {
                            selectedArea = area
                            viewModel.applyFilters(areaType: selectedArea, searchText: searchText)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Protocol List
    private var protocolList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredProtocols) { protocol in
                    ProtocolCard(protocol: protocol) {
                        selectedProtocol = protocol
                        showingProtocolDetail = true
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
            
            Text("Loading protocols...")
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(Color.white.opacity(0.4))
            
            Text("No Protocols Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Area Filter Chip
struct AreaFilterChip: View {
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

// MARK: - Protocol Card
struct ProtocolCard: View {
    let cleaningProtocol: CleaningProtocol
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cleaningProtocol.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(cleaningProtocol.description)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    priorityBadge
                }
                
                // Details
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        
                        Text("\(formatDuration(cleaningProtocol.requiredDuration))")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        
                        Text("\(cleaningProtocol.steps.count) steps")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        
                        Text(cleaningProtocol.areaType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                // Progress Bar (mock)
                ProgressView(value: Double.random(in: 0.6...0.9))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 43/255, green: 203/255, blue: 255/255)))
                    .scaleEffect(y: 0.8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
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
    
    private var priorityBadge: some View {
        Text(cleaningProtocol.priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch cleaningProtocol.priority {
        case .critical: return Color(red: 255/255, green: 100/255, blue: 100/255)
        case .high: return Color(red: 255/255, green: 200/255, blue: 100/255)
        case .medium: return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .low: return Color.white.opacity(0.6)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    ProtocolListView()
}
