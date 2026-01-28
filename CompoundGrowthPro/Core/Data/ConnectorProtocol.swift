import Foundation
import AppsFlyerLib
import WebKit
import Firebase
import FirebaseMessaging

protocol ConnectorProtocol {
    func obtain(marketingID: String) async throws -> [String: Any]
    func acquire(resource marketing: [String: Any]) async throws -> String
}

// UNIQUE: Gateway-style connector
final class Connector: ConnectorProtocol {
    
    private let gateway: URLSession
    private var responseCache: [String: CachedItem] = [:]
    
    private struct CachedItem {
        let payload: Any
        let moment: Date
    }
    
    init(gateway: URLSession = {
        let blueprint = URLSessionConfiguration.ephemeral
        blueprint.timeoutIntervalForRequest = 30
        blueprint.timeoutIntervalForResource = 90
        blueprint.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        blueprint.urlCache = nil
        return URLSession(configuration: blueprint)
    }()) {
        self.gateway = gateway
    }
    
    func obtain(marketingID: String) async throws -> [String: Any] {
        let origin = "https://gcdsdk.appsflyer.com/install_data/v4.0"
        let identifier = "id\(SystemConfig.appID)"
        
        var assembler = URLComponents(string: "\(origin)/\(identifier)")
        assembler?.queryItems = [
            URLQueryItem(name: "devkey", value: SystemConfig.devKey),
            URLQueryItem(name: "device_id", value: marketingID)
        ]
        
        guard let destination = assembler?.url else {
            throw ConnectorError.badPath
        }
        
        var message = URLRequest(url: destination, timeoutInterval: 30)
        message.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (payload, signal) = try await gateway.data(for: message)
        
        guard let response = signal as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw ConnectorError.badResponse
        }
        
        guard let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            throw ConnectorError.decodeFailed
        }
        
        return decoded
    }
    
    private var browser: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func acquire(resource marketing: [String: Any]) async throws -> String {
        guard let destination = URL(string: "https://iceballance.com/config.php") else {
            throw ConnectorError.badPath
        }
        
        var bundle: [String: Any] = marketing
        bundle["os"] = "iOS"
        bundle["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        bundle["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        bundle["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        bundle["store_id"] = "id\(SystemConfig.appID)"
        bundle["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        bundle["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var message = URLRequest(url: destination, timeoutInterval: 30)
        message.httpMethod = "POST"
        message.setValue("application/json", forHTTPHeaderField: "Content-Type")
        message.setValue(browser, forHTTPHeaderField: "User-Agent")
        message.httpBody = try JSONSerialization.data(withJSONObject: bundle)
        
        var lastIssue: Error?
        let pattern: [Double] = [2.5, 5.0, 10.0]
        
        for (cycle, pause) in pattern.enumerated() {
            do {
                let (payload, signal) = try await gateway.data(for: message)
                
                guard let response = signal as? HTTPURLResponse else {
                    throw ConnectorError.badResponse
                }
                
                if (200...299).contains(response.statusCode) {
                    guard let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any],
                          let success = decoded["ok"] as? Bool,
                          success,
                          let resource = decoded["url"] as? String else {
                        throw ConnectorError.decodeFailed
                    }
                    
                    return resource
                } else if response.statusCode == 429 {
                    let backoff = pause * Double(cycle + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw ConnectorError.badResponse
                }
            } catch {
                lastIssue = error
                if cycle < pattern.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        throw lastIssue ?? ConnectorError.badResponse
    }
}
