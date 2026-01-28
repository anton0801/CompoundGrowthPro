import SwiftUI

struct SystemConfig {
    static let appID = "6758301088"
    static let devKey = "q3tXWDM52htnTaugcPepRE"
}

@main
struct CompoundGrowthProApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            GrowthBalanceView()
        }
    }
}
