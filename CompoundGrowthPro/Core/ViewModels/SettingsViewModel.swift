import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var showExportSheet = false
    @Published var showImportSheet = false
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        self.settings = dataManager.loadSettings()
    }
    
    func saveSettings() {
        dataManager.saveSettings(settings)
    }
    
    func exportData() -> URL? {
        return dataManager.exportAllData()
    }
    
    func importData(from url: URL) -> Bool {
        return dataManager.importData(from: url)
    }
    
    func clearAllData() {
        dataManager.clearAllData()
        settings = AppSettings()
    }
}
