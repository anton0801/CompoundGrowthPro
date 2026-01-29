import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var isNew: Bool
    
    private let dataManager: DataManager
    
    init(profile: UserProfile? = nil, dataManager: DataManager = .shared) {
        if let profile = profile {
            self.profile = profile
            self.isNew = false
        } else {
            self.profile = UserProfile(name: "Новый профиль")
            self.isNew = true
        }
        self.dataManager = dataManager
    }
    
    func save() {
        dataManager.saveProfile(profile)
    }
}
