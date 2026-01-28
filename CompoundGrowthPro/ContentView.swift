import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @State private var showSplash = true
    @State private var showOnboarding = false
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            MainTabView()
        }
        .onAppear {
            if !dataManager.hasShownOnboarding() {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                dataManager.setOnboardingShown()
                showOnboarding = false
            }
        }
    }
}

struct MainTabView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardVM, selectedTab: $selectedTab)
                .tabItem {
                    Label("tab_home".localized, systemImage: "house.fill")
                }
                .tag(0)
            
            CalculatorView()
                .tabItem {
                    Label("tab_calculator".localized, systemImage: "plus.forwardslash.minus")
                }
                .tag(1)
            
            ComparisonView()
                .tabItem {
                    Label("tab_comparison".localized, systemImage: "chart.bar.xaxis")
                }
                .tag(2)
            
            GoalsView()
                .tabItem {
                    Label("tab_goals".localized, systemImage: "target")
                }
                .tag(3)
            
            EarlyPaymentView()
                .tabItem {
                    Label("tab_early_payment".localized, systemImage: "banknote")
                }
                .tag(4)
            
            HistoryView(viewModel: dashboardVM)
                .tabItem {
                    Label("tab_history".localized, systemImage: "clock.fill")
                }
                .tag(5)
            
            SettingsView()
                .tabItem {
                    Label("tab_settings".localized, systemImage: "gearshape.fill")
                }
                .tag(6)
        }
        .accentColor(Color(hex: "00B4A5"))
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var badge: Int?
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(color)
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CalculationCard: View {
    let calculation: Calculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(calculation.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(calculation.calculationType.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "00B4A5"))
                    )
            }
            
            if let result = calculation.result {
                VStack(spacing: 8) {
                    HStack {
                        Text("Итоговая сумма:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatCurrency(result.finalAmount, currency: calculation.currency))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                    
                    HStack {
                        Text("Прибыль:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatCurrency(result.totalInterest, currency: calculation.currency))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FFB300"))
                    }
                }
            }
            
            Text(formatDate(calculation.createdAt))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct TipsCard: View {
    let tips = [
        "💡 Начинайте инвестировать рано, чтобы использовать силу сложного процента",
        "📈 Регулярные вклады значительно увеличивают итоговую сумму",
        "🎯 Учитывайте инфляцию для реалистичной оценки прибыли",
        "💰 Диверсификация снижает риски инвестиций"
    ]
    
    @State private var currentTip = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Совет дня")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "FFB300"))
            }
            
            Text(tips[currentTip])
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FFB300").opacity(0.1),
                            Color(hex: "FFB300").opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .onAppear {
            currentTip = Int.random(in: 0..<tips.count)
        }
    }
}
//
//  CalculationDetailView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct CalculationDetailView: View {
    let calculation: Calculation
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack(spacing: 0) {
                    TabButton(title: "Overview", icon: "chart.pie.fill", isSelected: selectedTab == 0) {
                        withAnimation { selectedTab = 0 }
                    }
                    TabButton(title: "Chart", icon: "chart.xyaxis.line", isSelected: selectedTab == 1) {
                        withAnimation { selectedTab = 1 }
                    }
                    TabButton(title: "Details", icon: "list.bullet", isSelected: selectedTab == 2) {
                        withAnimation { selectedTab = 2 }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
                
                TabView(selection: $selectedTab) {
                    OverviewTab(calculation: calculation)
                        .tag(0)
                    
                    ChartTab(calculation: calculation)
                        .tag(1)
                    
                    DetailsTab(calculation: calculation)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(calculation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: "00B4A5") : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "00B4A5").opacity(0.1) : Color.clear)
            )
        }
    }
}

struct OverviewTab: View {
    let calculation: Calculation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = calculation.result {
                    // Main Result Card
                    VStack(spacing: 16) {
                        Text("Total sum")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.finalAmount, currency: calculation.currency))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                        
                        HStack(spacing: 30) {
                            VStack(spacing: 4) {
                                Text("Income")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(formatCurrency(result.totalInterest, currency: calculation.currency))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "FFB300"))
                            }
                            
                            VStack(spacing: 4) {
                                Text("Вклады")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(formatCurrency(result.totalContributions, currency: calculation.currency))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "00B4A5"))
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "4CAF50").opacity(0.1),
                                        Color(hex: "00B4A5").opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Additional Metrics
                    if calculation.inflationRate > 0 || calculation.taxRate > 0 {
                        VStack(spacing: 12) {
                            if calculation.inflationRate > 0 {
                                MetricRow(
                                    title: "Real income",
                                    value: formatCurrency(result.realReturn, currency: calculation.currency),
                                    icon: "arrow.down.circle.fill",
                                    color: Color(hex: "FF9800")
                                )
                            }
                            
                            if calculation.taxRate > 0 {
                                MetricRow(
                                    title: "After tax",
                                    value: formatCurrency(result.afterTaxReturn, currency: calculation.currency),
                                    icon: "percent",
                                    color: Color(hex: "00897B")
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // ROI Indicator
                    let roi = (result.totalInterest / result.totalContributions) * 100
                    ROIIndicator(roi: roi)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct ROIIndicator: View {
    let roi: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ROI")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                Text(String(format: "%.2f%%", roi))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(roi > 0 ? Color(hex: "4CAF50") : .red)
                
                Spacer()
                
                Image(systemName: roi > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(roi > 0 ? Color(hex: "4CAF50") : .red)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "00B4A5"),
                                    Color(hex: "4CAF50")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width * CGFloat(roi / 100), geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct ChartTab: View {
    let calculation: Calculation
    @State private var selectedDataPoint: YearData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = calculation.result {
                    // Interactive Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Chart up capital")
                            .font(.system(size: 18, weight: .semibold))
                        
                        InteractiveChartView(
                            data: result.yearlyBreakdown,
                            currency: calculation.currency,
                            selectedPoint: $selectedDataPoint
                        )
                        .frame(height: 300)
                        
                        if let point = selectedDataPoint {
                            DataPointInfo(point: point, currency: calculation.currency)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Year by Year Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Year by year breakdown")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal)
                        
                        ForEach(result.yearlyBreakdown) { yearData in
                            YearBreakdownCard(yearData: yearData, currency: calculation.currency)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct InteractiveChartView: View {
    let data: [YearData]
    let currency: Currency
    @Binding var selectedPoint: YearData?
    @State private var touchLocation: CGPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                Path { path in
                    let height = geometry.size.height
                    let step = height / 5
                    for i in 0...5 {
                        let y = CGFloat(i) * step
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
                // Gradient fill
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let maxBalance = data.map { $0.balance }.max() ?? 1
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    
                    path.addLine(to: CGPoint(
                        x: 0,
                        y: height - (CGFloat(data[0].balance / maxBalance) * height)
                    ))
                    
                    for (index, item) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(item.balance / maxBalance) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "00B4A5").opacity(0.3),
                            Color(hex: "00B4A5").opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Chart line
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let maxBalance = data.map { $0.balance }.max() ?? 1
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    
                    path.move(to: CGPoint(
                        x: 0,
                        y: height - (CGFloat(data[0].balance / maxBalance) * height)
                    ))
                    
                    for (index, item) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(item.balance / maxBalance) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "00B4A5"),
                            Color(hex: "4CAF50")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Touch indicator
                if let location = touchLocation, !data.isEmpty {
                    let maxBalance = data.map { $0.balance }.max() ?? 1
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    
                    let index = min(Int(location.x / stepX), data.count - 1)
                    let item = data[index]
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(item.balance / maxBalance) * height)
                    
                    Circle()
                        .fill(Color(hex: "00B4A5"))
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)
                    
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    .stroke(Color(hex: "00B4A5").opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchLocation = value.location
                        
                        let width = geometry.size.width
                        let stepX = width / CGFloat(data.count - 1)
                        let index = min(Int(value.location.x / stepX), data.count - 1)
                        selectedPoint = data[index]
                    }
                    .onEnded { _ in
                        touchLocation = nil
                    }
            )
        }
    }
}

struct DataPointInfo: View {
    let point: YearData
    let currency: Currency
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Year \(Int(point.year))")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(point.balance, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "4CAF50"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Percentage")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(point.interest, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FFB300"))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "00B4A5").opacity(0.1))
        )
    }
}

struct YearBreakdownCard: View {
    let yearData: YearData
    let currency: Currency
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Year \(Int(yearData.year))")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text(formatCurrency(yearData.balance, currency: currency))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "4CAF50"))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Percentage")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(yearData.interest, currency: currency))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "FFB300"))
                }
                
                if yearData.contribution > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Вклады")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(yearData.contribution, currency: currency))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "00B4A5"))
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct DetailsTab: View {
    let calculation: Calculation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Parameters Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Params")
                        .font(.system(size: 18, weight: .semibold))
                    
                    DetailRow(title: "Initial sum", value: formatCurrency(calculation.principal, currency: calculation.currency))
                    DetailRow(title: "Процентная ставка", value: "\(String(format: "%.2f", calculation.rate))%")
                    DetailRow(title: "Period", value: "\(Int(calculation.time)) лет")
                    DetailRow(title: "Частота начислений", value: calculation.compoundingFrequency.rawValue)
                    
                    if calculation.regularContribution > 0 {
                        DetailRow(title: "Регулярные вклады", value: formatCurrency(calculation.regularContribution, currency: calculation.currency))
                        DetailRow(title: "Частота вкладов", value: calculation.contributionFrequency.rawValue)
                    }
                    
                    if calculation.inflationRate > 0 {
                        DetailRow(title: "Inflation", value: "\(String(format: "%.2f", calculation.inflationRate))%")
                    }
                    
                    if calculation.taxRate > 0 {
                        DetailRow(title: "Tax", value: "\(String(format: "%.2f", calculation.taxRate))%")
                    }
                    
                    DetailRow(title: "Currency", value: calculation.currency.rawValue)
                    DetailRow(title: "Тип расчета", value: calculation.calculationType.rawValue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Formulas Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Формулы")
                        .font(.system(size: 18, weight: .semibold))
                    
                    FormulaCard()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct FormulaCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сложный процент:")
                .font(.system(size: 15, weight: .semibold))
            
            Text("A = P(1 + r/n)^(nt)")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "00B4A5"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "00B4A5").opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("где:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                FormulaVariable(symbol: "A", description: "Итоговая сумма")
                FormulaVariable(symbol: "P", description: "Начальная сумма")
                FormulaVariable(symbol: "r", description: "Годовая процентная ставка")
                FormulaVariable(symbol: "n", description: "Количество начислений в год")
                FormulaVariable(symbol: "t", description: "Время в годах")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct FormulaVariable: View {
    let symbol: String
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "FFB300"))
                .frame(width: 20)
            
            Text("–")
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
}

//
//  SettingsView.swift
//  CompoundGrowth Pro
//

import SwiftUI

func formatCurrency(_ value: Double, currency: Currency) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.groupingSeparator = " "
    
    let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "0.00"
    return "\(currency.symbol) \(formattedValue)"
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "ru_RU")
    return formatter.string(from: date)
}

func calculationTypeIcon(_ type: CalculationType) -> String {
    switch type {
    case .simple:
        return "function"
    case .compound:
        return "chart.line.uptrend.xyaxis"
    case .withContributions:
        return "arrow.up.circle.fill"
    case .investment:
        return "dollarsign.circle.fill"
    case .loan:
        return "creditcard.fill"
    case .retirement:
        return "person.fill"
    case .savings:
        return "banknote.fill"
    }
}
