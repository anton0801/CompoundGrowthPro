import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var particlesOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = 0
    @State private var showTitle = false
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        GeometryReader {g in
            ZStack {
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "00B4A5"),
                        Color(hex: "00897B"),
                        Color(hex: "FFB300"),
                        Color(hex: "00B4A5")
                    ]),
                    center: .center,
                    angle: .degrees(gradientRotation)
                )
                .ignoresSafeArea()
                
                Image("loading_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                
                ForEach(0..<20, id: \.self) { index in
                    FloatingParticle(index: index)
                        .opacity(particlesOpacity)
                }
                
                VStack(spacing: 24) {
                    // Logo with compound growth visual
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                        
                        // Logo circle
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                            
                            CompoundGraphIcon()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color(hex: "00897B"))
                        }
                        .scaleEffect(logoScale)
                        .rotationEffect(.degrees(logoRotation))
                    }
                    
                    // App title
                    if showTitle {
                        VStack(spacing: 8) {
                            Text("Growth")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Balance")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "FFB300"))
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .onAppear {
                startAnimations()
            }
        }
        .ignoresSafeArea()
    }
    
    private func startAnimations() {
        // Gradient rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        // Logo scale and rotation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            logoRotation = 5
        }
        
        // Particles fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            particlesOpacity = 1
        }
        
        // Background pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // Title appearance
        withAnimation(.easeOut(duration: 0.5).delay(1)) {
            showTitle = true
        }
        
    }
}

struct CompoundGraphIcon: View {
    @State private var drawProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height))
                
                // Exponential curve
                for i in 0...100 {
                    let x = CGFloat(i) / 100 * width
                    let progress = CGFloat(i) / 100
                    let y = height - (pow(progress, 2) * height * 0.8)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .trim(from: 0, to: drawProgress)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFB300"),
                        Color(hex: "00B4A5")
                    ]),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                drawProgress = 1
            }
        }
    }
}

struct FloatingParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        let symbols = ["₽", "$", "€", "£", "¥", "%"]
        let symbol = symbols[index % symbols.count]
        
        Text(symbol)
            .font(.system(size: CGFloat.random(in: 20...40), weight: .bold))
            .foregroundColor(.white)
            .opacity(opacity)
            .offset(x: xOffset, y: yOffset)
            .position(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
            )
            .onAppear {
                let delay = Double(index) * 0.1
                let duration = Double.random(in: 3...5)
                
                withAnimation(.easeInOut(duration: 0.5).delay(delay)) {
                    opacity = Double.random(in: 0.2...0.6)
                }
                
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    yOffset = CGFloat.random(in: -50...50)
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}


struct GrowthBalanceView: View {
    @StateObject private var engine = RuntimeEngine()
    @State private var eventStreams = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            renderPhase()
            
            if engine.presentAlertPrompt {
                AlertPromptView(engine: engine)
                    .transition(.opacity.combined(with: .scale))
            }
            
            if engine.phase == .unavailable {
                UnavailableView()
            }
        }
        .onAppear { attachEventStreams() }
    }
    
    @ViewBuilder
    private func renderPhase() -> some View {
        switch engine.phase {
        case .dormant, .awakening, .checking, .authorized:
            SplashScreenView()
        case .operational:
            if engine.activeResource != nil {
                BalanceContentView()
            } else {
                ContentView()
            }
        case .paused:
            ContentView()
        case .unavailable:
            EmptyView()
        }
    }
    
    private func attachEventStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { engine.ingest(marketing: $0) }
            .store(in: &eventStreams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { engine.ingest(navigation: $0) }
            .store(in: &eventStreams)
    }
}

struct UnavailableView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .blur(radius: 5)
            
            VStack {
                Spacer().frame(height: 200)
                Image("error_alert")
                Spacer()
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
