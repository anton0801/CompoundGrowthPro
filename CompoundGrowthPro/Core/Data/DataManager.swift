import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Publishers for real-time updates
    @Published var calculations: [Calculation] = []
    @Published var profiles: [UserProfile] = []
    @Published var goals: [FinancialGoal] = []
    @Published var settings: AppSettings = AppSettings()
    
    // Keys
    private enum Keys {
        static let onboardingShown = "onboardingShown"
        static let calculations = "calculationsHistory"
        static let profiles = "userProfiles"
        static let settings = "settings"
        static let currencyRates = "currencyRates"
        static let goals = "financialGoals"
        static let loanPayments = "loanPayments"
    }
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Load All Data
    func loadAllData() {
        calculations = loadCalculations()
        profiles = loadProfiles()
        goals = loadGoals()
        settings = loadSettings()
    }
    
    // MARK: - Onboarding
    func hasShownOnboarding() -> Bool {
        return userDefaults.bool(forKey: Keys.onboardingShown)
    }
    
    func setOnboardingShown() {
        userDefaults.set(true, forKey: Keys.onboardingShown)
    }
    
    // MARK: - Calculations
    private func loadCalculations() -> [Calculation] {
        guard let data = userDefaults.data(forKey: Keys.calculations) else {
            return []
        }
        
        do {
            let calculations = try JSONDecoder().decode([Calculation].self, from: data)
            return calculations.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Error loading calculations: \(error)")
            return []
        }
    }
    
    func saveCalculation(_ calculation: Calculation) {
        var currentCalculations = calculations
        
        if let index = currentCalculations.firstIndex(where: { $0.id == calculation.id }) {
            currentCalculations[index] = calculation
        } else {
            currentCalculations.insert(calculation, at: 0)
        }
        
        // Limit to 100 calculations
        if currentCalculations.count > 100 {
            currentCalculations = Array(currentCalculations.prefix(100))
        }
        
        do {
            let data = try JSONEncoder().encode(currentCalculations)
            userDefaults.set(data, forKey: Keys.calculations)
            
            // Update published property
            DispatchQueue.main.async {
                self.calculations = currentCalculations
            }
            
            // Post notification
            NotificationCenter.default.post(name: .calculationsDidChange, object: nil)
        } catch {
            print("Error saving calculation: \(error)")
        }
    }
    
    func deleteCalculation(_ calculation: Calculation) {
        var currentCalculations = calculations
        currentCalculations.removeAll(where: { $0.id == calculation.id })
        
        do {
            let data = try JSONEncoder().encode(currentCalculations)
            userDefaults.set(data, forKey: Keys.calculations)
            
            // Update published property
            DispatchQueue.main.async {
                self.calculations = currentCalculations
            }
            
            // Post notification
            NotificationCenter.default.post(name: .calculationsDidChange, object: nil)
        } catch {
            print("Error deleting calculation: \(error)")
        }
    }
    
    // MARK: - Profiles
    private func loadProfiles() -> [UserProfile] {
        guard let data = userDefaults.data(forKey: Keys.profiles) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([UserProfile].self, from: data)
        } catch {
            print("Error loading profiles: \(error)")
            return []
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        var currentProfiles = profiles
        
        if let index = currentProfiles.firstIndex(where: { $0.id == profile.id }) {
            currentProfiles[index] = profile
        } else {
            currentProfiles.append(profile)
        }
        
        do {
            let data = try JSONEncoder().encode(currentProfiles)
            userDefaults.set(data, forKey: Keys.profiles)
            
            // Update published property
            DispatchQueue.main.async {
                self.profiles = currentProfiles
            }
            
            // Post notification
            NotificationCenter.default.post(name: .profilesDidChange, object: nil)
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    func deleteProfile(_ profile: UserProfile) {
        var currentProfiles = profiles
        currentProfiles.removeAll(where: { $0.id == profile.id })
        
        do {
            let data = try JSONEncoder().encode(currentProfiles)
            userDefaults.set(data, forKey: Keys.profiles)
            
            // Update published property
            DispatchQueue.main.async {
                self.profiles = currentProfiles
            }
            
            // Post notification
            NotificationCenter.default.post(name: .profilesDidChange, object: nil)
        } catch {
            print("Error deleting profile: \(error)")
        }
    }
    
    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.settings) else {
            return AppSettings()
        }
        
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            print("Error loading settings: \(error)")
            return AppSettings()
        }
    }
    
    func saveSettings(_ newSettings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(newSettings)
            userDefaults.set(data, forKey: Keys.settings)
            
            // Update published property
            DispatchQueue.main.async {
                self.settings = newSettings
            }
            
            // Post notification
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    // MARK: - Goals
    private func loadGoals() -> [FinancialGoal] {
        guard let data = userDefaults.data(forKey: Keys.goals) else {
            return []
        }
        
        do {
            let goals = try JSONDecoder().decode([FinancialGoal].self, from: data)
            return goals.sorted(by: { $0.deadline < $1.deadline })
        } catch {
            print("Error loading goals: \(error)")
            return []
        }
    }
    
    func saveGoal(_ goal: FinancialGoal) {
        var currentGoals = goals
        
        if let index = currentGoals.firstIndex(where: { $0.id == goal.id }) {
            currentGoals[index] = goal
        } else {
            currentGoals.append(goal)
        }
        
        currentGoals.sort(by: { $0.deadline < $1.deadline })
        
        do {
            let data = try JSONEncoder().encode(currentGoals)
            userDefaults.set(data, forKey: Keys.goals)
            
            // Update published property
            DispatchQueue.main.async {
                self.goals = currentGoals
            }
            
            // Post notification
            NotificationCenter.default.post(name: .goalsDidChange, object: nil)
        } catch {
            print("Error saving goal: \(error)")
        }
    }
    
    func deleteGoal(_ goal: FinancialGoal) {
        var currentGoals = goals
        currentGoals.removeAll(where: { $0.id == goal.id })
        
        do {
            let data = try JSONEncoder().encode(currentGoals)
            userDefaults.set(data, forKey: Keys.goals)
            
            // Update published property
            DispatchQueue.main.async {
                self.goals = currentGoals
            }
            
            // Post notification
            NotificationCenter.default.post(name: .goalsDidChange, object: nil)
        } catch {
            print("Error deleting goal: \(error)")
        }
    }
    
    // MARK: - Loan Payments
    func loadLoanPayments() -> [LoanPayment] {
        guard let data = userDefaults.data(forKey: Keys.loanPayments) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([LoanPayment].self, from: data)
        } catch {
            print("Error loading loan payments: \(error)")
            return []
        }
    }
    
    func saveLoanPayment(_ loanPayment: LoanPayment) {
        var payments = loadLoanPayments()
        
        if let index = payments.firstIndex(where: { $0.id == loanPayment.id }) {
            payments[index] = loanPayment
        } else {
            payments.append(loanPayment)
        }
        
        // Limit to 50 loan payments
        if payments.count > 50 {
            payments = Array(payments.prefix(50))
        }
        
        do {
            let data = try JSONEncoder().encode(payments)
            userDefaults.set(data, forKey: Keys.loanPayments)
        } catch {
            print("Error saving loan payment: \(error)")
        }
    }
    
    // MARK: - Export/Import
    func exportAllData() -> URL? {
        let exportData: [String: Any] = [
            "calculations": try? JSONEncoder().encode(calculations).base64EncodedString(),
            "profiles": try? JSONEncoder().encode(profiles).base64EncodedString(),
            "settings": try? JSONEncoder().encode(settings).base64EncodedString(),
            "goals": try? JSONEncoder().encode(goals).base64EncodedString(),
            "loanPayments": try? JSONEncoder().encode(loadLoanPayments()).base64EncodedString(),
            "version": "1.1",
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CompoundGrowthPro_backup_v1.1.json")
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
    
    func importData(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            
            // Import calculations
            if let calculationsString = json["calculations"] as? String,
               let calculationsData = Data(base64Encoded: calculationsString) {
                let importedCalculations = try JSONDecoder().decode([Calculation].self, from: calculationsData)
                let encodedData = try JSONEncoder().encode(importedCalculations)
                userDefaults.set(encodedData, forKey: Keys.calculations)
                
                DispatchQueue.main.async {
                    self.calculations = importedCalculations
                }
            }
            
            // Import profiles
            if let profilesString = json["profiles"] as? String,
               let profilesData = Data(base64Encoded: profilesString) {
                let importedProfiles = try JSONDecoder().decode([UserProfile].self, from: profilesData)
                let encodedData = try JSONEncoder().encode(importedProfiles)
                userDefaults.set(encodedData, forKey: Keys.profiles)
                
                DispatchQueue.main.async {
                    self.profiles = importedProfiles
                }
            }
            
            // Import settings
            if let settingsString = json["settings"] as? String,
               let settingsData = Data(base64Encoded: settingsString) {
                let importedSettings = try JSONDecoder().decode(AppSettings.self, from: settingsData)
                let encodedData = try JSONEncoder().encode(importedSettings)
                userDefaults.set(encodedData, forKey: Keys.settings)
                
                DispatchQueue.main.async {
                    self.settings = importedSettings
                }
            }
            
            // Import goals
            if let goalsString = json["goals"] as? String,
               let goalsData = Data(base64Encoded: goalsString) {
                let importedGoals = try JSONDecoder().decode([FinancialGoal].self, from: goalsData)
                let encodedData = try JSONEncoder().encode(importedGoals)
                userDefaults.set(encodedData, forKey: Keys.goals)
                
                DispatchQueue.main.async {
                    self.goals = importedGoals
                }
            }
            
            // Import loan payments
            if let paymentsString = json["loanPayments"] as? String,
               let paymentsData = Data(base64Encoded: paymentsString) {
                let payments = try JSONDecoder().decode([LoanPayment].self, from: paymentsData)
                let encodedData = try JSONEncoder().encode(payments)
                userDefaults.set(encodedData, forKey: Keys.loanPayments)
            }
            
            // Reload all data
            loadAllData()
            
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
    
    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.calculations)
        userDefaults.removeObject(forKey: Keys.profiles)
        userDefaults.removeObject(forKey: Keys.settings)
        userDefaults.removeObject(forKey: Keys.currencyRates)
        userDefaults.removeObject(forKey: Keys.goals)
        userDefaults.removeObject(forKey: Keys.loanPayments)
        
        loadAllData()
    }
}

extension Notification.Name {
    static let calculationsDidChange = Notification.Name("calculationsDidChange")
    static let profilesDidChange = Notification.Name("profilesDidChange")
    static let goalsDidChange = Notification.Name("goalsDidChange")
    static let settingsDidChange = Notification.Name("settingsDidChange")
}
