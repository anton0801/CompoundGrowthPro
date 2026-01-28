import Foundation

protocol RepositoryProtocol {
    func store(marketing: [String: Any])
    func fetch() -> MarketingContext
    func store(navigation: [String: Any])
    func fetchNavigation() -> NavigationContext
    func store(resource: String)
    func fetchResource() -> String?
    func store(behavior: String)
    func fetchBehavior() -> String?
    func flagFirstRunComplete()
    func checkFirstRun() -> Bool
    func store(alertApproval: Bool)
    func checkAlertApproval() -> Bool
    func store(alertRejection: Bool)
    func checkAlertRejection() -> Bool
    func store(alertRequestTime: Date)
    func fetchAlertRequestTime() -> Date?
}
