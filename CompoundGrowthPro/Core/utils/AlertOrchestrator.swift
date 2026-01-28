import Foundation
import UserNotifications


final class AlertOrchestrator: NSObject {
    func process(payload: [AnyHashable: Any]) {
        guard let resource = extract(from: payload) else { return }
        UserDefaults.standard.set(resource, forKey: "temp_url")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "temp_url_moment")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("LoadTempURL"), object: nil, userInfo: ["temp_url": resource])
        }
    }
    
    private func extract(from payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any], let url = nested["url"] as? String { return url }
        if let wrapped = payload["aps"] as? [String: Any], let nested = wrapped["data"] as? [String: Any], let url = nested["url"] as? String { return url }
        if let extended = payload["custom"] as? [String: Any], let url = extended["target_url"] as? String { return url }
        return nil
    }
}
