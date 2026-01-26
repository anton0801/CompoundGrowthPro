import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let onboardingShown = "onboardingShown"
        static let calculations = "calculationsHistory"
        static let profiles = "userProfiles"
        static let settings = "settings"
        static let currencyRates = "currencyRates"
    }
    
    private init() {}
    
    // MARK: - Onboarding
    func hasShownOnboarding() -> Bool {
        return userDefaults.bool(forKey: Keys.onboardingShown)
    }
    
    func setOnboardingShown() {
        userDefaults.set(true, forKey: Keys.onboardingShown)
    }
    
    // MARK: - Calculations
    func loadCalculations() -> [Calculation] {
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
        var calculations = loadCalculations()
        
        if let index = calculations.firstIndex(where: { $0.id == calculation.id }) {
            calculations[index] = calculation
        } else {
            calculations.append(calculation)
        }
        
        // Limit to 100 calculations
        if calculations.count > 100 {
            calculations = Array(calculations.prefix(100))
        }
        
        do {
            let data = try JSONEncoder().encode(calculations)
            userDefaults.set(data, forKey: Keys.calculations)
        } catch {
            print("Error saving calculation: \(error)")
        }
    }
    
    func deleteCalculation(_ calculation: Calculation) {
        var calculations = loadCalculations()
        calculations.removeAll(where: { $0.id == calculation.id })
        
        do {
            let data = try JSONEncoder().encode(calculations)
            userDefaults.set(data, forKey: Keys.calculations)
        } catch {
            print("Error deleting calculation: \(error)")
        }
    }
    
    // MARK: - Profiles
    func loadProfiles() -> [UserProfile] {
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
        var profiles = loadProfiles()
        
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: Keys.profiles)
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    func deleteProfile(_ profile: UserProfile) {
        var profiles = loadProfiles()
        profiles.removeAll(where: { $0.id == profile.id })
        
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: Keys.profiles)
        } catch {
            print("Error deleting profile: \(error)")
        }
    }
    
    // MARK: - Settings
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
    
    func saveSettings(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: Keys.settings)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    // MARK: - Export/Import
    func exportAllData() -> URL? {
        let calculations = loadCalculations()
        let profiles = loadProfiles()
        let settings = loadSettings()
        
        let exportData: [String: Any] = [
            "calculations": try? JSONEncoder().encode(calculations).base64EncodedString(),
            "profiles": try? JSONEncoder().encode(profiles).base64EncodedString(),
            "settings": try? JSONEncoder().encode(settings).base64EncodedString(),
            "version": "1.0",
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CompoundGrowthPro_backup.json")
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
            
            if let calculationsString = json["calculations"] as? String,
               let calculationsData = Data(base64Encoded: calculationsString) {
                let calculations = try JSONDecoder().decode([Calculation].self, from: calculationsData)
                let encodedData = try JSONEncoder().encode(calculations)
                userDefaults.set(encodedData, forKey: Keys.calculations)
            }
            
            if let profilesString = json["profiles"] as? String,
               let profilesData = Data(base64Encoded: profilesString) {
                let profiles = try JSONDecoder().decode([UserProfile].self, from: profilesData)
                let encodedData = try JSONEncoder().encode(profiles)
                userDefaults.set(encodedData, forKey: Keys.profiles)
            }
            
            if let settingsString = json["settings"] as? String,
               let settingsData = Data(base64Encoded: settingsString) {
                let settings = try JSONDecoder().decode(AppSettings.self, from: settingsData)
                let encodedData = try JSONEncoder().encode(settings)
                userDefaults.set(encodedData, forKey: Keys.settings)
            }
            
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
    }
}
