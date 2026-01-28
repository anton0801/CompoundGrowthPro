import Foundation
import Combine
import AppsFlyerLib
import UIKit
import UserNotifications
import Network

@MainActor
final class RuntimeEngine: ObservableObject {
    
    @Published private(set) var phase: RuntimePhase = .dormant
    @Published private(set) var activeResource: String?
    @Published var presentAlertPrompt: Bool = false
    
    private let repository: RepositoryProtocol
    private let inspector: InspectorProtocol
    private let connector: ConnectorProtocol
    
    private var marketingCtx = MarketingContext(content: [:])
    private var navigationCtx = NavigationContext(content: [:])
    private var runtimeConfig = RuntimeConfiguration(
        resource: nil,
        behavior: nil,
        isFirstRun: true,
        alertsApproved: false,
        alertsRejected: false,
        lastAlertRequest: nil
    )
    
    private var observers = Set<AnyCancellable>()
    private var watchdog: Task<Void, Never>?
    private var locked = false
    
    private let monitor = NWPathMonitor()
    
    init(
        repository: RepositoryProtocol = Repository(),
        inspector: InspectorProtocol = Inspector(),
        connector: ConnectorProtocol = Connector()
    ) {
        self.repository = repository
        self.inspector = inspector
        self.connector = connector
        
        loadConfiguration()
        watchConnectivity()
        boot()
    }
    
    func ingest(marketing data: [String: Any]) {
        marketingCtx = MarketingContext(content: data)
        repository.store(marketing: data)
        
        Task {
            await runInspection()
        }
    }
    
    func ingest(navigation data: [String: Any]) {
        navigationCtx = NavigationContext(content: data)
        repository.store(navigation: data)
    }
    
    func approveAlerts() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] approved, _ in
            Task { @MainActor in
                self?.repository.store(alertApproval: approved)
                self?.repository.store(alertRejection: !approved)
                self?.runtimeConfig.alertsApproved = approved
                self?.runtimeConfig.alertsRejected = !approved
                
                if approved {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self?.presentAlertPrompt = false
            }
        }
    }
    
    func postponeAlerts() {
        repository.store(alertRequestTime: Date())
        runtimeConfig.lastAlertRequest = Date()
        presentAlertPrompt = false
    }
    
    private func loadConfiguration() {
        runtimeConfig = RuntimeConfiguration(
            resource: repository.fetchResource(),
            behavior: repository.fetchBehavior(),
            isFirstRun: repository.checkFirstRun(),
            alertsApproved: repository.checkAlertApproval(),
            alertsRejected: repository.checkAlertRejection(),
            lastAlertRequest: repository.fetchAlertRequestTime()
        )
    }
    
    private func boot() {
        phase = .awakening
        armWatchdog()
    }
    
    private func armWatchdog() {
        watchdog = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            if !locked {
                await MainActor.run {
                    self.phase = .paused
                }
            }
        }
    }
    
    private func watchConnectivity() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self, !self.locked else { return }
                
                if path.status == .satisfied {
                    if self.phase == .unavailable {
                        self.phase = .paused
                    }
                } else {
                    self.phase = .unavailable
                }
            }
        }
        monitor.start(queue: .global(qos: .background))
    }
    
    private func runInspection() async {
        guard activeResource == nil else { return }
        
        phase = .checking
        
        do {
            let valid = try await inspector.inspect()
            
            if valid {
                phase = .authorized
                await advance()
            } else {
                phase = .paused
            }
        } catch {
            phase = .paused
        }
    }
    
    private func advance() async {
        if marketingCtx.isEmpty {
            recoverResource()
            return
        }
        
        if runtimeConfig.behavior == "Inactive" {
            phase = .paused
            return
        }
        
        if needsFirstRunFlow() {
            await executeFirstRunFlow()
            return
        }
        
        if let temporary = UserDefaults.standard.string(forKey: "temp_url") {
            engage(resource: temporary)
            return
        }
        
        await obtainResource()
    }
    
    private func needsFirstRunFlow() -> Bool {
        runtimeConfig.isFirstRun && marketingCtx.isNaturalSource
    }
    
    private func executeFirstRunFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let obtained = try await connector.obtain(marketingID: deviceID)
            
            var merged = obtained
            for (key, value) in navigationCtx.content {
                if merged[key] == nil {
                    merged[key] = value
                }
            }
            
            marketingCtx = MarketingContext(content: merged)
            repository.store(marketing: merged)
            
            await obtainResource()
        } catch {
            phase = .paused
        }
    }
    
    private func obtainResource() async {
        do {
            let resource = try await connector.acquire(resource: marketingCtx.content)
            
            repository.store(resource: resource)
            repository.store(behavior: "Active")
            repository.flagFirstRunComplete()
            
            runtimeConfig.resource = resource
            runtimeConfig.behavior = "Active"
            runtimeConfig.isFirstRun = false
            
            engage(resource: resource)
        } catch {
            recoverResource()
        }
    }
    
    private func recoverResource() {
        if let cached = runtimeConfig.resource {
            engage(resource: cached)
        } else {
            phase = .paused
        }
    }
    
    private func engage(resource: String) {
        guard !locked else { return }
        
        watchdog?.cancel()
        activeResource = resource
        phase = .operational(resource: resource)
        locked = true
        
        if runtimeConfig.shouldRequestAlerts {
            presentAlertPrompt = true
        }
    }
}
