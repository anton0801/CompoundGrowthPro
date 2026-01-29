import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var calculations: [Calculation] = []
    @Published var profiles: [UserProfile] = []
    @Published var settings: AppSettings
    @Published var searchText = ""
    @Published var selectedProfile: UserProfile?
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    var filteredCalculations: [Calculation] {
        if searchText.isEmpty {
            if let profileID = selectedProfile?.id {
                return calculations.filter { $0.profileID == profileID }
            }
            return calculations
        } else {
            return calculations.filter { calculation in
                calculation.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var recentCalculations: [Calculation] {
        Array(calculations.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3))
    }
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        self.settings = dataManager.settings
        
        // Subscribe to DataManager's published properties
        setupSubscriptions()
        
        // Initial load
        loadData()
    }
    
    private func setupSubscriptions() {
        // Subscribe to calculations changes
        dataManager.$calculations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCalculations in
                self?.calculations = newCalculations
            }
            .store(in: &cancellables)
        
        // Subscribe to profiles changes
        dataManager.$profiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProfiles in
                self?.profiles = newProfiles
            }
            .store(in: &cancellables)
        
        // Subscribe to settings changes
        dataManager.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSettings in
                self?.settings = newSettings
            }
            .store(in: &cancellables)
        
        // Also listen to notifications as backup
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataDidChange),
            name: .calculationsDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataDidChange),
            name: .profilesDidChange,
            object: nil
        )
    }
    
    @objc private func dataDidChange() {
        loadData()
    }
    
    func loadData() {
        calculations = dataManager.calculations
        profiles = dataManager.profiles
        settings = dataManager.settings
    }
    
    func deleteCalculation(_ calculation: Calculation) {
        dataManager.deleteCalculation(calculation)
    }
    
    func deleteProfile(_ profile: UserProfile) {
        dataManager.deleteProfile(profile)
    }
    
    func selectProfile(_ profile: UserProfile?) {
        selectedProfile = profile
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
