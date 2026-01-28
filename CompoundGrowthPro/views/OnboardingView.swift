import SwiftUI
import WebKit
import Combine

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    var onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "onboarding_title_1".localized,
            description: "onboarding_desc_1".localized,
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "00B4A5")
        ),
        OnboardingPage(
            title: "onboarding_title_2".localized,
            description: "onboarding_desc_2".localized,
            icon: "chart.bar.fill",
            color: Color(hex: "FFB300")
        ),
        OnboardingPage(
            title: "onboarding_title_3".localized,
            description: "onboarding_desc_3".localized,
            icon: "folder.fill.badge.gearshape",
            color: Color(hex: "4CAF50")
        ),
        OnboardingPage(
            title: "onboarding_title_4".localized,
            description: "onboarding_desc_4".localized,
            icon: "lock.shield.fill",
            color: Color(hex: "00897B")
        )
    ]
    
    var body: some View {
        ZStack {
            // Background with parallax effect
            ForEach(0..<pages.count, id: \.self) { index in
                ParallaxBackground(color: pages[index].color, index: index, currentPage: currentPage)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onComplete()
                    }) {
                        Text("skip".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], index: index, currentPage: $currentPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        PageIndicator(isActive: index == currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack {
                        Text(currentPage == pages.count - 1 ? "start".localized : "next".localized)
                            .font(.system(size: 18, weight: .semibold))
                        
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                pages[currentPage].color,
                                pages[currentPage].color.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: pages[currentPage].color.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    @Binding var currentPage: Int
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -10
    @State private var textOpacity: Double = 0
    @State private var particlesVisible = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon with particles
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                page.color.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 30)
                
                // Orbiting particles
                if particlesVisible {
                    ForEach(0..<8, id: \.self) { particleIndex in
                        OrbitingParticle(
                            index: particleIndex,
                            total: 8,
                            color: page.color
                        )
                    }
                }
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: page.color.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(page.color)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            }
            .frame(height: 300)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
            }
            
            Spacer()
        }
        .onChange(of: currentPage) { newValue in
            if newValue == index {
                animateIn()
            }
        }
        .onAppear {
            if currentPage == index {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        // Reset states
        iconScale = 0.5
        iconRotation = -10
        textOpacity = 0
        particlesVisible = false
        
        // Animate icon
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            textOpacity = 1
        }
        
        // Show particles
        withAnimation(.easeIn(duration: 0.3).delay(0.6)) {
            particlesVisible = true
        }
    }
}

struct OrbitingParticle: View {
    let index: Int
    let total: Int
    let color: Color
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.6))
            .frame(width: 8, height: 8)
            .offset(y: -100)
            .rotationEffect(.degrees(rotation + Double(index) * (360.0 / Double(total))))
            .onAppear {
                withAnimation(
                    .linear(duration: 8)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

struct ParallaxBackground: View {
    let color: Color
    let index: Int
    let currentPage: Int
    
    var body: some View {
        let offset = CGFloat(currentPage - index) * UIScreen.main.bounds.width
        let opacity = 1.0 - abs(Double(currentPage - index)) * 0.3
        
        ZStack {
            color
                .ignoresSafeArea()
                .opacity(opacity)
                .offset(x: offset * 0.3)
            
            // Geometric patterns
            GeometricPattern(color: color)
                .opacity(0.1)
                .offset(x: offset * 0.5)
        }
    }
}

struct GeometricPattern: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size = geometry.size
                let gridSize: CGFloat = 60
                
                for i in stride(from: 0, to: size.width + gridSize, by: gridSize) {
                    for j in stride(from: 0, to: size.height + gridSize, by: gridSize) {
                        path.addEllipse(in: CGRect(x: i, y: j, width: 30, height: 30))
                    }
                }
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
    }
}

struct PageIndicator: View {
    let isActive: Bool
    
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(isActive ? 1 : 0.4))
            .frame(width: isActive ? 24 : 8, height: 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

struct BalanceContentView: View {
    @State private var targetResource: String? = ""
    @State private var viewReady = false
    
    var body: some View {
        ZStack {
            if viewReady, let urlString = targetResource, let url = URL(string: urlString) {
                BalanceWebInterface(resource: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initializeView() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reinitializeView() }
    }
    
    private func initializeView() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "gb_res_primary") ?? ""
        targetResource = temp ?? stored
        viewReady = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reinitializeView() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            viewReady = false
            targetResource = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { viewReady = true }
        }
    }
}

struct BalanceWebInterface: UIViewRepresentable {
    let resource: URL
    
    func makeCoordinator() -> BalanceNavigator { BalanceNavigator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let interface = constructInterface(navigator: context.coordinator)
        context.coordinator.interface = interface
        context.coordinator.launch(resource: resource, in: interface)
        Task { await context.coordinator.restoreSession(in: interface) }
        return interface
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func constructInterface(navigator: BalanceNavigator) -> WKWebView {
        let blueprint = WKWebViewConfiguration()
        blueprint.processPool = WKProcessPool()
        
        let settings = WKPreferences()
        settings.javaScriptEnabled = true
        settings.javaScriptCanOpenWindowsAutomatically = true
        blueprint.preferences = settings
        
        let scriptManager = WKUserContentController()
        let bootstrapScript = WKUserScript(
            source: """
            (function() {
                const metaTag = document.createElement('meta');
                metaTag.name = 'viewport';
                metaTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(metaTag);
                const styleTag = document.createElement('style');
                styleTag.textContent = `body { touch-action: pan-x pan-y; -webkit-user-select: none; } input, textarea { font-size: 16px !important; }`;
                document.head.appendChild(styleTag);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        scriptManager.addUserScript(bootstrapScript)
        blueprint.userContentController = scriptManager
        blueprint.allowsInlineMediaPlayback = true
        blueprint.mediaTypesRequiringUserActionForPlayback = []
        
        let contentPrefs = WKWebpagePreferences()
        contentPrefs.allowsContentJavaScript = true
        blueprint.defaultWebpagePreferences = contentPrefs
        
        let interface = WKWebView(frame: .zero, configuration: blueprint)
        interface.scrollView.minimumZoomScale = 1.0
        interface.scrollView.maximumZoomScale = 1.0
        interface.scrollView.bounces = false
        interface.scrollView.bouncesZoom = false
        interface.allowsBackForwardNavigationGestures = true
        interface.scrollView.contentInsetAdjustmentBehavior = .never
        interface.navigationDelegate = navigator
        interface.uiDelegate = navigator
        return interface
    }
}

final class BalanceNavigator: NSObject {
    weak var interface: WKWebView?
    
    private var hops = 0
    private var hopLimit = 70
    private var anchor: URL?
    private var trail: [URL] = []
    private var sanctuary: URL?
    private var windows: [WKWebView] = []
    private let vaultKey = "balance_vault"
    
    func launch(resource: URL, in interface: WKWebView) {
        print("🚀 [Growth] Launch: \(resource.absoluteString)")
        trail = [resource]
        hops = 0
        var dispatch = URLRequest(url: resource)
        dispatch.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        interface.load(dispatch)
    }
    
    func restoreSession(in interface: WKWebView) {
        guard let vault = UserDefaults.standard.object(forKey: vaultKey) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = interface.configuration.websiteDataStore.httpCookieStore
        let items = vault.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        items.forEach { store.setCookie($0) }
    }
    
    func archiveSession(from interface: WKWebView) {
        let store = interface.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { [weak self] items in
            guard let self = self else { return }
            var vault: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for item in items {
                var domain = vault[item.domain] ?? [:]
                if let props = item.properties {
                    domain[item.name] = props
                }
                vault[item.domain] = domain
            }
            UserDefaults.standard.set(vault, forKey: self.vaultKey)
        }
    }
}

extension BalanceNavigator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let target = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        anchor = target
        if isNavigable(target) {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(target, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    private func isNavigable(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let schemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let special = ["srcdoc", "about:blank", "about:srcdoc"]
        return schemes.contains(scheme) || special.contains { path.hasPrefix($0) } || path == "about:blank"
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        hops += 1
        if hops > hopLimit {
            webView.stopLoading()
            if let recovery = anchor { webView.load(URLRequest(url: recovery)) }
            hops = 0
            return
        }
        anchor = webView.url
        archiveSession(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url {
            sanctuary = current
            print("✅ [Growth] Commit: \(current.absoluteString)")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { sanctuary = current }
        hops = 0
        archiveSession(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorHTTPTooManyRedirects, let recovery = anchor {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension BalanceNavigator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let window = WKWebView(frame: webView.bounds, configuration: configuration)
        window.navigationDelegate = self
        window.uiDelegate = self
        window.allowsBackForwardNavigationGestures = true
        webView.addSubview(window)
        window.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            window.topAnchor.constraint(equalTo: webView.topAnchor),
            window.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            window.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            window.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let closeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closeWindow(_:)))
        closeGesture.edges = .left
        window.addGestureRecognizer(closeGesture)
        windows.append(window)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            window.load(navigationAction.request)
        }
        return window
    }
    
    @objc private func closeWindow(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let lastWindow = windows.last {
            lastWindow.removeFromSuperview()
            windows.removeLast()
        } else {
            interface?.goBack()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
