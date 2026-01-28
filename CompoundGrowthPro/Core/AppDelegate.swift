import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private let marketingOrchestrator = MarketingOrchestrator()
    private let alertOrchestrator = AlertOrchestrator()
    private var trackingOrchestrator: TrackingOrchestrator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        marketingOrchestrator.onMarketingData = { [weak self] in self?.broadcast(marketing: $0) }
        marketingOrchestrator.onNavigationData = { [weak self] in self?.broadcast(navigation: $0) }
        trackingOrchestrator = TrackingOrchestrator(orchestrator: marketingOrchestrator)
        initializeCore()
        initializeAlerts()
        initializeTracking()
        if let alert = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            alertOrchestrator.process(payload: alert)
        }
        observeLifecycle()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func initializeCore() {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
    }
    
    private func initializeAlerts() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func initializeTracking() {
        trackingOrchestrator?.setup()
    }
    
    private func observeLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(lifecycleActivated), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func lifecycleActivated() {
        trackingOrchestrator?.initiate()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        alertOrchestrator.process(payload: userInfo)
        completionHandler(.newData)
    }
    
    private func broadcast(marketing data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
        }
    }
    
    private func broadcast(navigation data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.growth.vault1")?.set(token, forKey: "shared_token")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "token_moment")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        alertOrchestrator.process(payload: notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        alertOrchestrator.process(payload: response.notification.request.content.userInfo)
        completionHandler()
    }
}

final class MarketingOrchestrator: NSObject {
    var onMarketingData: (([AnyHashable: Any]) -> Void)?
    var onNavigationData: (([AnyHashable: Any]) -> Void)?
    
    private var marketingBuffer: [AnyHashable: Any] = [:]
    private var navigationBuffer: [AnyHashable: Any] = [:]
    private var fusionTimer: Timer?
    private let processedMarker = "gb_marketing_fused"
    
    func receive(marketing data: [AnyHashable: Any]) {
        marketingBuffer = data
        scheduleFusion()
        if !navigationBuffer.isEmpty { fuse() }
    }
    
    func receive(navigation data: [AnyHashable: Any]) {
        guard !hasBeenFused() else { return }
        navigationBuffer = data
        onNavigationData?(data)
        fusionTimer?.invalidate()
        if !marketingBuffer.isEmpty { fuse() }
    }
    
    private func scheduleFusion() {
        fusionTimer?.invalidate()
        fusionTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.fuse() }
    }
    
    private func fuse() {
        var fused = marketingBuffer
        navigationBuffer.forEach { key, value in
            let augmentedKey = "deep_\(key)"
            if fused[augmentedKey] == nil { fused[augmentedKey] = value }
        }
        onMarketingData?(fused)
    }
    
    private func hasBeenFused() -> Bool {
        UserDefaults.standard.bool(forKey: processedMarker)
    }
}

final class TrackingOrchestrator: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var orchestrator: MarketingOrchestrator
    
    init(orchestrator: MarketingOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    func setup() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = SystemConfig.devKey
        sdk.appleAppID = SystemConfig.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func initiate() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "tracking_state")
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "tracking_moment")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        orchestrator.receive(marketing: data)
    }
    
    func onConversionDataFail(_ error: Error) {
        var errorData: [AnyHashable: Any] = [:]
        errorData["error"] = true
        errorData["error_info"] = error.localizedDescription
        orchestrator.receive(marketing: errorData)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let deepLink = result.deepLink else { return }
        orchestrator.receive(navigation: deepLink.clickEvent)
    }
}
