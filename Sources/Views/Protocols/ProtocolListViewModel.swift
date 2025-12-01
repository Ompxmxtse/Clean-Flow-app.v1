import Foundation
import FirebaseFirestore

@MainActor
class ProtocolListViewModel: ObservableObject {
    @Published var protocols: [CleaningProtocol] = []
    @Published var filteredProtocols: [CleaningProtocol] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func loadProtocols() {
        isLoading = true
        errorMessage = nil
        
        listenerRegistration?.remove()
        listenerRegistration = db.collection("protocols")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                let protocols = snapshot?.documents.compactMap { document in
                    try? document.data(as: CleaningProtocol.self)
                } ?? []
                
                self.protocols = protocols
                self.filteredProtocols = protocols
                self.isLoading = false
            }
    }
    
    func applyFilters(areaType: CleaningProtocol.AreaType?, searchText: String) {
        var filtered = protocols
        
        // Apply area filter
        if let areaType = areaType {
            filtered = filtered.filter { $0.areaType == areaType }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { cleaningProtocol in
                cleaningProtocol.name.localizedCaseInsensitiveContains(searchText) ||
                cleaningProtocol.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredProtocols = filtered
    }
}
