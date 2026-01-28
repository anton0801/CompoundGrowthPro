import Foundation
import FirebaseDatabase
import FirebaseAuth
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import CommonCrypto

final class Repository: RepositoryProtocol {
    
    // UNIQUE: Triple-vault system
    private let vault1 = UserDefaults(suiteName: "group.growth.vault1")!
    private let vault2 = UserDefaults.standard
    
    // UNIQUE: Flash memory
    private var flash: [String: Any] = [:]
    
    // UNIQUE: Encrypted archive
    private var archive: [String: Data] = [:]
    
    // UNIQUE: Data compartments
    private var marketingData: [String: Any] = [:]
    private var navigationData: [String: Any] = [:]
    
    // UNIQUE: Key scheme
    private enum Key {
        static let resource = "gb_res_primary"
        static let behavior = "gb_mode_active"
        static let firstRun = "gb_virgin_state"
        static let alertYes = "gb_alert_yes"
        static let alertNo = "gb_alert_no"
        static let alertWhen = "gb_alert_when"
        static let marketingArchive = "gb_marketing_arc"
        static let navigationArchive = "gb_navigation_arc"
    }
    
    init() {
        prepareFlash()
    }
    
    // MARK: - Marketing
    
    func store(marketing data: [String: Any]) {
        marketingData = data
        flash["marketing"] = data
        
        if let json = toJSON(data) {
            vault1.set(json, forKey: Key.marketingArchive)
            
            if let compressed = compress(json) {
                archive["marketing"] = compressed
            }
        }
    }
    
    func fetch() -> MarketingContext {
        if !marketingData.isEmpty {
            return MarketingContext(content: marketingData)
        }
        
        if let json = vault1.string(forKey: Key.marketingArchive),
           let data = fromJSON(json) {
            return MarketingContext(content: data)
        }
        
        return MarketingContext(content: [:])
    }
    
    // MARK: - Navigation
    
    func store(navigation data: [String: Any]) {
        navigationData = data
        flash["navigation"] = data
        
        if let json = toJSON(data) {
            let transformed = transform(json)
            vault1.set(transformed, forKey: Key.navigationArchive)
        }
    }
    
    func fetchNavigation() -> NavigationContext {
        if !navigationData.isEmpty {
            return NavigationContext(content: navigationData)
        }
        
        if let transformed = vault1.string(forKey: Key.navigationArchive),
           let json = untransform(transformed),
           let data = fromJSON(json) {
            return NavigationContext(content: data)
        }
        
        return NavigationContext(content: [:])
    }
    
    // MARK: - Resource
    
    func store(resource: String) {
        vault2.set(resource, forKey: Key.resource)
        vault1.set(resource, forKey: Key.resource)
        flash[Key.resource] = resource
        
        let digest = calculateDigest(resource)
        vault2.set(digest, forKey: "\(Key.resource)_digest")
    }
    
    func fetchResource() -> String? {
        if let cached = flash[Key.resource] as? String {
            return cached
        }
        
        if let stored = vault1.string(forKey: Key.resource) {
            return stored
        }
        
        return vault2.string(forKey: Key.resource)
    }
    
    // MARK: - Behavior
    
    func store(behavior: String) {
        vault1.set(behavior, forKey: Key.behavior)
        flash["behavior"] = behavior
    }
    
    func fetchBehavior() -> String? {
        if let cached = flash["behavior"] as? String {
            return cached
        }
        return vault1.string(forKey: Key.behavior)
    }
    
    // MARK: - First Run
    
    func flagFirstRunComplete() {
        vault1.set(true, forKey: Key.firstRun)
    }
    
    func checkFirstRun() -> Bool {
        !vault1.bool(forKey: Key.firstRun)
    }
    
    // MARK: - Alerts
    
    func store(alertApproval: Bool) {
        vault1.set(alertApproval, forKey: Key.alertYes)
        vault2.set(alertApproval, forKey: Key.alertYes)
    }
    
    func checkAlertApproval() -> Bool {
        vault1.bool(forKey: Key.alertYes)
    }
    
    func store(alertRejection: Bool) {
        vault1.set(alertRejection, forKey: Key.alertNo)
    }
    
    func checkAlertRejection() -> Bool {
        vault1.bool(forKey: Key.alertNo)
    }
    
    func store(alertRequestTime date: Date) {
        let ms = date.timeIntervalSince1970 * 1000
        vault1.set(ms, forKey: Key.alertWhen)
    }
    
    func fetchAlertRequestTime() -> Date? {
        let ms = vault1.double(forKey: Key.alertWhen)
        return ms > 0 ? Date(timeIntervalSince1970: ms / 1000) : nil
    }
    
    // MARK: - Helpers
    
    private func prepareFlash() {
        if let resource = vault1.string(forKey: Key.resource) {
            flash[Key.resource] = resource
        }
    }
    
    private func toJSON(_ data: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
    
    private func fromJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    private func compress(_ string: String) -> Data? {
        let cipher = "GrowthBalance2024"
        var output = Data()
        
        for (idx, char) in string.enumerated() {
            let cipherIdx = cipher.index(cipher.startIndex, offsetBy: idx % cipher.count)
            let cipherChar = cipher[cipherIdx]
            let encrypted = (char.asciiValue ?? 0) ^ (cipherChar.asciiValue ?? 0)
            output.append(encrypted)
        }
        
        return output
    }
    
    private func transform(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "*")
            .replacingOccurrences(of: "+", with: "@")
    }
    
    private func untransform(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "*", with: "=")
            .replacingOccurrences(of: "@", with: "+")
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func calculateDigest(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
