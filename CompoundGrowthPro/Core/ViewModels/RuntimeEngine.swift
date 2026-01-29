import Foundation
import Combine
import AppsFlyerLib
import UIKit
import UserNotifications
import Network

@MainActor
final class RuntimeEngine: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var phase: RuntimePhase = .dormant
    @Published private(set) var activeResource: String?
    @Published var presentAlertPrompt: Bool = false
    
    // MARK: - Dependencies
    private let repository: RepositoryProtocol
    private let inspector: InspectorProtocol
    private let connector: ConnectorProtocol
    
    // MARK: - State Management (NEW STRUCTURE)
    private var marketingCtx = MarketingContext(content: [:])
    private var navigationCtx = NavigationContext(content: [:])
    
    // UNIQUE: Separate state holders instead of single config
    private var cachedEndpoint: String?
    private var operationMode: String?
    private var virginLaunch: Bool = true
    private var notificationState: NotificationState = .unknown
    private var lastPromptMoment: Date?
    
    // UNIQUE: State management
    private enum NotificationState {
        case unknown
        case accepted
        case declined
    }
    
    private var subscriptions = Set<AnyCancellable>()
    private var guardTimer: Task<Void, Never>?
    private var engineLocked = false
    
    private let networkWatcher = NWPathMonitor()
    
    // MARK: - Initialization (RESTRUCTURED)
    init(
        repository: RepositoryProtocol = Repository(),
        inspector: InspectorProtocol = Inspector(),
        connector: ConnectorProtocol = Connector()
    ) {
        self.repository = repository
        self.inspector = inspector
        self.connector = connector
        
        // UNIQUE: Separate loading instead of loadConfiguration()
        restoreState()
        setupNetworkObserver()
        initiateStartup()
    }
    
    // MARK: - Public Interface
    
    func ingest(marketing data: [String: Any]) {
        marketingCtx = MarketingContext(content: data)
        repository.store(marketing: data)
        
        Task {
            await performCheck()
        }
    }
    
    func ingest(navigation data: [String: Any]) {
        navigationCtx = NavigationContext(content: data)
        repository.store(navigation: data)
    }
    
    func approveAlerts() {
        requestNotificationAuthorization { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.repository.store(alertApproval: granted)
                self.repository.store(alertRejection: !granted)
                self.notificationState = granted ? .accepted : .declined
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self.presentAlertPrompt = false
            }
        }
    }
    
    func postponeAlerts() {
        let now = Date()
        repository.store(alertRequestTime: now)
        lastPromptMoment = now
        presentAlertPrompt = false
    }
    
    // MARK: - Private Implementation (COMPLETELY NEW LOGIC)
    
    // UNIQUE: Split configuration loading
    private func restoreState() {
        // Load individually instead of single config object
        cachedEndpoint = repository.fetchResource()
        operationMode = repository.fetchBehavior()
        virginLaunch = repository.checkFirstRun()
        
        // UNIQUE: Convert bool to enum
        let approved = repository.checkAlertApproval()
        let declined = repository.checkAlertRejection()
        
        if approved {
            notificationState = .accepted
        } else if declined {
            notificationState = .declined
        } else {
            notificationState = .unknown
        }
        
        lastPromptMoment = repository.fetchAlertRequestTime()
    }
    
    // UNIQUE: Different startup sequence
    private func initiateStartup() {
        phase = .awakening
        activateGuard()
    }
    
    // UNIQUE: Guard instead of watchdog
    private func activateGuard() {
        guardTimer = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard !engineLocked else { return }
            
            await MainActor.run {
                self.phase = .paused
            }
        }
    }
    
    // UNIQUE: Observer instead of monitor
    private func setupNetworkObserver() {
        networkWatcher.pathUpdateHandler = { [weak self] currentPath in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard !self.engineLocked else { return }
                
                let isConnected = currentPath.status == .satisfied
                
                if isConnected {
                    if self.phase == .unavailable {
                        self.phase = .paused
                    }
                } else {
                    self.phase = .unavailable
                }
            }
        }
        networkWatcher.start(queue: .global(qos: .background))
    }
    
    // UNIQUE: Check instead of inspection
    private func performCheck() async {
        // Don't check if already have resource
        if activeResource != nil { return }
        
        phase = .checking
        
        do {
            let isValid = try await inspector.inspect()
            
            if isValid {
                phase = .authorized
                await continueExecution()
            } else {
                phase = .paused
            }
        } catch {
            phase = .paused
        }
    }
    
    // UNIQUE: Different flow logic with guard statements
    private func continueExecution() async {
        // Guard 1: Check if we have marketing data
        guard !marketingCtx.isEmpty else {
            loadCachedEndpoint()
            return
        }
        
        // Guard 2: Check operation mode
        guard operationMode != "Inactive" else {
            phase = .paused
            return
        }
        
        // Guard 3: Check for temporary URL
        if let tempURL = UserDefaults.standard.string(forKey: "temp_url") {
            activateWithResource(tempURL)
            return
        }
        
        // Guard 4: Check first launch scenario
        if shouldExecuteFirstLaunch() {
            await handleFirstLaunch()
            return
        }
        
        // Default: Fetch endpoint
        await fetchEndpoint()
    }
    
    // UNIQUE: Different condition check
    private func shouldExecuteFirstLaunch() -> Bool {
        return virginLaunch && marketingCtx.isNaturalSource
    }
    
    // UNIQUE: Different first launch flow
    private func handleFirstLaunch() async {
        // Wait 5 seconds
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            // Get device identifier
            let identifier = AppsFlyerLib.shared().getAppsFlyerUID()
            
            // Fetch attribution
            let attribution = try await connector.obtain(marketingID: identifier)
            
            // UNIQUE: Merge differently
            var combined = attribution
            
            // Add navigation data if not present
            for (navKey, navValue) in navigationCtx.content {
                if combined[navKey] == nil {
                    combined[navKey] = navValue
                }
            }
            
            // Update context
            marketingCtx = MarketingContext(content: combined)
            repository.store(marketing: combined)
            
            // Continue to fetch endpoint
            await fetchEndpoint()
            
        } catch {
            phase = .paused
        }
    }
    
    // UNIQUE: Different endpoint fetching
    private func fetchEndpoint() async {
        do {
            // Acquire resource
            let endpoint = try await connector.acquire(resource: marketingCtx.content)
            
            // Store results
            repository.store(resource: endpoint)
            repository.store(behavior: "Active")
            repository.flagFirstRunComplete()
            
            // Update local state
            cachedEndpoint = endpoint
            operationMode = "Active"
            virginLaunch = false
            
            // Activate
            activateWithResource(endpoint)
            
        } catch {
            loadCachedEndpoint()
        }
    }
    
    // UNIQUE: Different cached loading
    private func loadCachedEndpoint() {
        if let cached = cachedEndpoint {
            activateWithResource(cached)
        } else {
            phase = .paused
        }
    }
    
    // UNIQUE: Different activation logic
    private func activateWithResource(_ endpoint: String) {
        // Prevent re-activation
        guard !engineLocked else { return }
        
        // Cancel guard
        guardTimer?.cancel()
        
        // Set state
        activeResource = endpoint
        phase = .operational(resource: endpoint)
        engineLocked = true
        
        // UNIQUE: Check notification prompt differently
        if canShowNotificationPrompt() {
            presentAlertPrompt = true
        }
    }
    
    // UNIQUE: Separate prompt check logic
    private func canShowNotificationPrompt() -> Bool {
        // Check notification state
        guard notificationState == .unknown else {
            return false
        }
        
        // Check last prompt time
        if let lastPrompt = lastPromptMoment {
            let elapsed = Date().timeIntervalSince(lastPrompt)
            let days = elapsed / 86400
            return days >= 3
        }
        
        return true
    }
    
    // UNIQUE: Separate authorization request
    private func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        center.requestAuthorization(options: options) { granted, _ in
            completion(granted)
        }
    }
}
