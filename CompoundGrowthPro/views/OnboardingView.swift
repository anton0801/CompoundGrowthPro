import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    var onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Сила сложного процента",
            description: "Откройте потенциал экспоненциального роста ваших инвестиций с точными расчетами",
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "00B4A5")
        ),
        OnboardingPage(
            title: "Визуализируйте будущее",
            description: "Интерактивные графики и сравнение сценариев помогут принять правильное решение",
            icon: "chart.bar.fill",
            color: Color(hex: "FFB300")
        ),
        OnboardingPage(
            title: "Управляйте сценариями",
            description: "Сохраняйте расчеты, создавайте профили и отслеживайте историю ваших финансовых планов",
            icon: "folder.fill.badge.gearshape",
            color: Color(hex: "4CAF50")
        ),
        OnboardingPage(
            title: "Начните расти сегодня",
            description: "Все данные хранятся локально, обеспечивая полную приватность ваших финансов",
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
                        Text("Пропустить")
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
                        Text(currentPage == pages.count - 1 ? "Начать" : "Далее")
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
