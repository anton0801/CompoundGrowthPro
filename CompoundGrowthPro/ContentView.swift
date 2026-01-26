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
        Group {
            if showSplash {
                SplashScreenView {
                    withAnimation {
                        showSplash = false
                        if !dataManager.hasShownOnboarding() {
                            showOnboarding = true
                        }
                    }
                }
            } else if showOnboarding {
                OnboardingView {
                    withAnimation {
                        dataManager.setOnboardingShown()
                        showOnboarding = false
                    }
                }
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardVM)
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(0)
            
            CalculatorView()
                .tabItem {
                    Label("Калькулятор", systemImage: "plus.forwardslash.minus")
                }
                .tag(1)
            
            HistoryView(viewModel: dashboardVM)
                .tabItem {
                    Label("История", systemImage: "clock.fill")
                }
                .tag(2)
            
            ProfilesView(viewModel: dashboardVM)
                .tabItem {
                    Label("Профили", systemImage: "person.2.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "00B4A5"))
    }
}

//
//  DashboardView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showNewCalculation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Добро пожаловать")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("CompoundGrowth Pro")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        QuickActionCard(
                            title: "Новый расчет",
                            icon: "plus.circle.fill",
                            color: Color(hex: "00B4A5")
                        ) {
                            showNewCalculation = true
                        }
                        
                        QuickActionCard(
                            title: "История",
                            icon: "clock.fill",
                            color: Color(hex: "FFB300"),
                            badge: viewModel.calculations.count
                        ) {
                            // Navigate to history
                        }
                        
                        QuickActionCard(
                            title: "Профили",
                            icon: "person.2.fill",
                            color: Color(hex: "4CAF50"),
                            badge: viewModel.profiles.count
                        ) {
                            // Navigate to profiles
                        }
                        
                        QuickActionCard(
                            title: "Графики",
                            icon: "chart.bar.fill",
                            color: Color(hex: "FF9800")
                        ) {
                            // Navigate to charts
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Calculations
                    if !viewModel.recentCalculations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Недавние расчеты")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            ForEach(viewModel.recentCalculations) { calculation in
                                CalculationCard(calculation: calculation)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Tips Section
                    TipsCard()
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewCalculation) {
            NavigationView {
                CalculatorView()
            }
        }
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
//  CalculatorView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showResult = false
    @State private var showSaveSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Calculation Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Тип расчета")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CalculationType.allCases, id: \.self) { type in
                                    TypeChip(
                                        title: type.rawValue,
                                        isSelected: viewModel.calculation.calculationType == type
                                    ) {
                                        viewModel.calculation.calculationType = type
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        CurrencyInputField(
                            title: "Начальная сумма",
                            value: $viewModel.calculation.principal,
                            currency: viewModel.calculation.currency
                        )
                        
                        PercentageInputField(
                            title: "Годовая ставка",
                            value: $viewModel.calculation.rate
                        )
                        
                        SliderInputField(
                            title: "Период (лет)",
                            value: $viewModel.calculation.time,
                            range: 1...50,
                            step: 1
                        )
                        
                        PickerInputField(
                            title: "Частота начислений",
                            selection: $viewModel.calculation.compoundingFrequency,
                            options: CompoundingFrequency.allCases
                        )
                        
                        if viewModel.calculation.calculationType == .withContributions ||
                           viewModel.calculation.calculationType == .retirement {
                            CurrencyInputField(
                                title: "Регулярные вклады",
                                value: $viewModel.calculation.regularContribution,
                                currency: viewModel.calculation.currency
                            )
                            
                            PickerInputField(
                                title: "Частота вкладов",
                                selection: $viewModel.calculation.contributionFrequency,
                                options: ContributionFrequency.allCases
                            )
                        }
                        
                        // Advanced Options
                        DisclosureGroup("Дополнительные параметры") {
                            VStack(spacing: 20) {
                                PercentageInputField(
                                    title: "Инфляция",
                                    value: $viewModel.calculation.inflationRate
                                )
                                
                                PercentageInputField(
                                    title: "Налоговая ставка",
                                    value: $viewModel.calculation.taxRate
                                )
                                
                                PickerInputField(
                                    title: "Валюта",
                                    selection: $viewModel.calculation.currency,
                                    options: Currency.allCases
                                )
                            }
                            .padding(.top)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                    }
                    .padding(.horizontal)
                    
                    // Calculate Button
                    Button(action: {
                        viewModel.calculate()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showResult = true
                        }
                    }) {
                        HStack {
                            if viewModel.isCalculating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "function")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Рассчитать")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "00B4A5"),
                                    Color(hex: "00897B")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Color(hex: "00B4A5").opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .disabled(viewModel.isCalculating)
                    .padding(.horizontal)
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .padding(.horizontal)
                    }
                    
                    // Result
                    if showResult, let result = viewModel.calculation.result {
                        ResultView(calculation: viewModel.calculation, result: result)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale))
                        
                        // Save Button
                        Button(action: {
                            showSaveSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Сохранить расчет")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "00B4A5"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "00B4A5"), lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Калькулятор")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveCalculationSheet(calculation: $viewModel.calculation) {
                viewModel.saveCalculation()
                showSaveSheet = false
            }
        }
    }
}

// Input Field Components
struct CurrencyInputField: View {
    let title: String
    @Binding var value: Double
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(currency.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "00B4A5"))
                
                TextField("0", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct PercentageInputField: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                TextField("0", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("%")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "FFB300"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct SliderInputField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "00B4A5"))
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(Color(hex: "00B4A5"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct PickerInputField<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct TypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "00B4A5") : Color(.systemGray5))
                )
        }
    }
}

struct ResultView: View {
    let calculation: Calculation
    let result: CalculationResult
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Результаты")
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ResultCard(
                title: "Итоговая сумма",
                value: formatCurrency(result.finalAmount, currency: calculation.currency),
                color: Color(hex: "4CAF50"),
                icon: "chart.line.uptrend.xyaxis"
            )
            
            ResultCard(
                title: "Прибыль",
                value: formatCurrency(result.totalInterest, currency: calculation.currency),
                color: Color(hex: "FFB300"),
                icon: "dollarsign.circle.fill"
            )
            
            if calculation.inflationRate > 0 {
                ResultCard(
                    title: "Реальная прибыль (с инфляцией)",
                    value: formatCurrency(result.realReturn, currency: calculation.currency),
                    color: Color(hex: "FF9800"),
                    icon: "arrow.down.circle.fill"
                )
            }
            
            if calculation.taxRate > 0 {
                ResultCard(
                    title: "После налогов",
                    value: formatCurrency(result.afterTaxReturn, currency: calculation.currency),
                    color: Color(hex: "00897B"),
                    icon: "percent"
                )
            }
            
            // Chart
            if !result.yearlyBreakdown.isEmpty {
                ChartView(data: result.yearlyBreakdown, currency: calculation.currency)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
        )
    }
}

struct ChartView: View {
    let data: [YearData]
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("График роста")
                .font(.system(size: 16, weight: .semibold))
            
            GeometryReader { geometry in
                ZStack {
                    // Grid lines
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
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct SaveCalculationSheet: View {
    @Binding var calculation: Calculation
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название расчета")) {
                    TextField("Введите название", text: $calculation.name)
                }
            }
            .navigationTitle("Сохранить расчет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}


//
//  HistoryView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showFilterSheet = false
    @State private var selectedCalculation: Calculation?
    @State private var showDeleteAlert = false
    @State private var calculationToDelete: Calculation?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.calculations.isEmpty {
                    EmptyStateView(
                        icon: "clock.fill",
                        title: "Нет сохраненных расчетов",
                        description: "Создайте свой первый расчет и он появится здесь"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Search Bar
                            SearchBar(text: $viewModel.searchText)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            // Calculations List
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredCalculations) { calculation in
                                    HistoryCalculationCard(calculation: calculation)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            selectedCalculation = calculation
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                // Edit calculation
                                            }) {
                                                Label("Редактировать", systemImage: "pencil")
                                            }
                                            
                                            Button(action: {
                                                // Duplicate calculation
                                            }) {
                                                Label("Дублировать", systemImage: "doc.on.doc")
                                            }
                                            
                                            Button(role: .destructive, action: {
                                                calculationToDelete = calculation
                                                showDeleteAlert = true
                                            }) {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color(hex: "00B4A5"))
                    }
                }
            }
        }
        .sheet(item: $selectedCalculation) { calculation in
            CalculationDetailView(calculation: calculation)
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet()
        }
        .alert("Удалить расчет?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                if let calculation = calculationToDelete {
                    viewModel.deleteCalculation(calculation)
                }
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
}

struct HistoryCalculationCard: View {
    let calculation: Calculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculation.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formatDate(calculation.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: calculationTypeIcon(calculation.calculationType))
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "00B4A5"))
                }
            }
            
            Divider()
            
            if let result = calculation.result {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Итого")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.finalAmount, currency: calculation.currency))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Прибыль")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.totalInterest, currency: calculation.currency))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FFB300"))
                    }
                }
            }
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TagView(text: calculation.calculationType.rawValue, color: .blue)
                    TagView(text: "\(Int(calculation.time)) лет", color: .green)
                    if calculation.regularContribution > 0 {
                        TagView(text: "С вкладами", color: .orange)
                    }
                    if calculation.inflationRate > 0 {
                        TagView(text: "С инфляцией", color: .red)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Поиск расчетов...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
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
                    TabButton(title: "Обзор", icon: "chart.pie.fill", isSelected: selectedTab == 0) {
                        withAnimation { selectedTab = 0 }
                    }
                    TabButton(title: "График", icon: "chart.xyaxis.line", isSelected: selectedTab == 1) {
                        withAnimation { selectedTab = 1 }
                    }
                    TabButton(title: "Детали", icon: "list.bullet", isSelected: selectedTab == 2) {
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
                    Button("Готово") {
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
                        Text("Итоговая сумма")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.finalAmount, currency: calculation.currency))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                        
                        HStack(spacing: 30) {
                            VStack(spacing: 4) {
                                Text("Прибыль")
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
                                    title: "Реальная прибыль",
                                    value: formatCurrency(result.realReturn, currency: calculation.currency),
                                    icon: "arrow.down.circle.fill",
                                    color: Color(hex: "FF9800")
                                )
                            }
                            
                            if calculation.taxRate > 0 {
                                MetricRow(
                                    title: "После налогов",
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
            Text("Рентабельность инвестиций (ROI)")
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
                        Text("График роста капитала")
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
                        Text("Разбивка по годам")
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
            Text("Год \(Int(point.year))")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Баланс")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(point.balance, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "4CAF50"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Проценты")
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
                Text("Год \(Int(yearData.year))")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text(formatCurrency(yearData.balance, currency: currency))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "4CAF50"))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Проценты")
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
                    Text("Параметры расчета")
                        .font(.system(size: 18, weight: .semibold))
                    
                    DetailRow(title: "Начальная сумма", value: formatCurrency(calculation.principal, currency: calculation.currency))
                    DetailRow(title: "Процентная ставка", value: "\(String(format: "%.2f", calculation.rate))%")
                    DetailRow(title: "Период", value: "\(Int(calculation.time)) лет")
                    DetailRow(title: "Частота начислений", value: calculation.compoundingFrequency.rawValue)
                    
                    if calculation.regularContribution > 0 {
                        DetailRow(title: "Регулярные вклады", value: formatCurrency(calculation.regularContribution, currency: calculation.currency))
                        DetailRow(title: "Частота вкладов", value: calculation.contributionFrequency.rawValue)
                    }
                    
                    if calculation.inflationRate > 0 {
                        DetailRow(title: "Инфляция", value: "\(String(format: "%.2f", calculation.inflationRate))%")
                    }
                    
                    if calculation.taxRate > 0 {
                        DetailRow(title: "Налоговая ставка", value: "\(String(format: "%.2f", calculation.taxRate))%")
                    }
                    
                    DetailRow(title: "Валюта", value: calculation.currency.rawValue)
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
//  ProfilesView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct ProfilesView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showCreateProfile = false
    @State private var selectedProfile: UserProfile?
    @State private var showDeleteAlert = false
    @State private var profileToDelete: UserProfile?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.profiles.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "Нет профилей",
                        description: "Создайте профиль для организации своих расчетов"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                ProfileCard(profile: profile)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        viewModel.selectProfile(profile)
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            selectedProfile = profile
                                        }) {
                                            Label("Редактировать", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            profileToDelete = profile
                                            showDeleteAlert = true
                                        }) {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Профили")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateProfile = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "00B4A5"))
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateProfile) {
            ProfileEditView(viewModel: ProfileViewModel()) {
                viewModel.loadData()
            }
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileEditView(viewModel: ProfileViewModel(profile: profile)) {
                viewModel.loadData()
            }
        }
        .alert("Удалить профиль?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                if let profile = profileToDelete {
                    viewModel.deleteProfile(profile)
                }
            }
        } message: {
            Text("Все расчеты в этом профиле будут сохранены")
        }
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "00B4A5"),
                                    Color(hex: "00897B")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(profile.name.prefix(2).uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formatDate(profile.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Расчетов")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("\(profile.calculationIDs.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "00B4A5"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Валюта")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(profile.defaultCurrency.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FFB300"))
                }
                
                if profile.defaultInflationRate > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Инфляция")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", profile.defaultInflationRate))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FF9800"))
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название профиля", text: $viewModel.profile.name)
                }
                
                Section(header: Text("Настройки по умолчанию")) {
                    Picker("Валюта", selection: $viewModel.profile.defaultCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    
                    HStack {
                        Text("Инфляция")
                        Spacer()
                        TextField("0", value: $viewModel.profile.defaultInflationRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("Создан: \(formatDate(viewModel.profile.createdAt))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(viewModel.isNew ? "Новый профиль" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        viewModel.save()
                        onSave()
                        dismiss()
                    }
                    .disabled(viewModel.profile.name.isEmpty)
                }
            }
        }
    }
}

//
//  SettingsView.swift
//  CompoundGrowth Pro
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showExportSuccess = false
    @State private var showImportPicker = false
    @State private var showClearAlert = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("Внешний вид")) {
                    Picker("Тема", selection: $viewModel.settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .onChange(of: viewModel.settings.theme) { _ in
                        viewModel.saveSettings()
                    }
                }
                
                // Default Settings
                Section(header: Text("Настройки по умолчанию")) {
                    Picker("Валюта", selection: $viewModel.settings.defaultCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.rawValue)
                            }
                            .tag(currency)
                        }
                    }
                    .onChange(of: viewModel.settings.defaultCurrency) { _ in
                        viewModel.saveSettings()
                    }
                }
                
                // Notifications
                Section(header: Text("Уведомления")) {
                    Toggle("Напоминания", isOn: $viewModel.settings.notificationsEnabled)
                        .onChange(of: viewModel.settings.notificationsEnabled) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                // Security
                Section(header: Text("Безопасность")) {
                    Toggle("Биометрия", isOn: $viewModel.settings.biometricAuthEnabled)
                        .onChange(of: viewModel.settings.biometricAuthEnabled) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                // Data Management
                Section(header: Text("Управление данными")) {
                    Button(action: {
                        if let url = viewModel.exportData() {
                            shareFile(url: url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "00B4A5"))
                            Text("Экспортировать данные")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        showImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(Color(hex: "FFB300"))
                            Text("Импортировать данные")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        showClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Очистить все данные")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Currency Rates
                Section(header: Text("Курсы валют")) {
                    NavigationLink(destination: CurrencyRatesView(settings: $viewModel.settings)) {
                        Text("Управление курсами")
                    }
                }
                
                // About
                Section(header: Text("О приложении")) {
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color(hex: "00B4A5"))
                            Text("О CompoundGrowth Pro")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    NavigationLink(destination: FAQView()) {
                        Text("FAQ")
                    }
                    
                    NavigationLink(destination: FormulasView()) {
                        Text("Формулы и расчеты")
                    }
                    
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Очистить все данные?", isPresented: $showClearAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Очистить", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("Это действие удалит все расчеты, профили и настройки. Данное действие нельзя отменить.")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker { url in
                _ = viewModel.importData(from: url)
            }
        }
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct CurrencyRatesView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Курсы относительно USD")) {
                ForEach(Array(settings.currencyRates.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        TextField("0.0", value: Binding(
                            get: { settings.currencyRates[key] ?? 1.0 },
                            set: { settings.currencyRates[key] = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                }
            }
            
            Section {
                Button("Обновить курсы") {
                    // Manual update functionality
                    dismiss()
                }
            }
        }
        .navigationTitle("Курсы валют")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "00B4A5"),
                                        Color(hex: "00897B")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        CompoundGraphIcon()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("CompoundGrowth Pro")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Версия 1.0.0")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("О приложении")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal)
                        
                        Text("CompoundGrowth Pro — мощное приложение для расчета сложного процента с обширным функционалом для финансового планирования. Моделируйте рост инвестиций, анализируйте кредиты и оптимизируйте сбережения с помощью интерактивных графиков и детальных расчетов.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Точные расчеты", description: "Профессиональные формулы")
                        FeatureRow(icon: "chart.bar.fill", title: "Визуализация", description: "Интерактивные графики")
                        FeatureRow(icon: "lock.shield.fill", title: "Приватность", description: "Все данные локально")
                        FeatureRow(icon: "gearshape.fill", title: "Настройки", description: "Гибкая конфигурация")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                    
                    Text("© 2026 CompoundGrowth Pro\nВсе права защищены")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "00B4A5"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct FAQView: View {
    let faqs = [
        FAQ(question: "Что такое сложный процент?", answer: "Сложный процент — это проценты, начисляемые на первоначальную сумму и на проценты, накопленные за предыдущие периоды. Это создает эффект 'процентов на проценты', приводя к экспоненциальному росту."),
        FAQ(question: "Как часто начисляются проценты?", answer: "Частота начислений влияет на итоговую сумму. Чем чаще начисляются проценты (ежедневно, ежемесячно, ежегодно), тем больше будет итоговая сумма при одинаковой годовой ставке."),
        FAQ(question: "Что такое реальная прибыль?", answer: "Реальная прибыль учитывает влияние инфляции на покупательную способность ваших денег. Это показывает, сколько вы реально заработали с учетом роста цен."),
        FAQ(question: "Как сохранить расчет?", answer: "После выполнения расчета нажмите кнопку 'Сохранить расчет', введите название и сохраните. Все расчеты хранятся локально на вашем устройстве."),
        FAQ(question: "Можно ли экспортировать данные?", answer: "Да! В настройках выберите 'Экспортировать данные' для создания резервной копии всех расчетов и профилей в формате JSON.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(faqs) { faq in
                    FAQCard(faq: faq)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Часто задаваемые вопросы")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQCard: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "00B4A5"))
                }
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct FormulasView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FormulaSection(
                    title: "Сложный процент",
                    formula: "A = P(1 + r/n)^(nt)",
                    description: "Основная формула для расчета сложного процента с периодическим начислением.",
                    variables: [
                        ("A", "Итоговая сумма"),
                        ("P", "Начальная сумма (Principal)"),
                        ("r", "Годовая процентная ставка (в десятичной форме)"),
                        ("n", "Количество начислений в год"),
                        ("t", "Время в годах")
                    ]
                )
                
                FormulaSection(
                    title: "С регулярными вкладами",
                    formula: "FV = P(1 + r/n)^(nt) + PMT × [((1 + r/n)^(nt) - 1) / (r/n)]",
                    description: "Расчет с учетом регулярных дополнительных взносов.",
                    variables: [
                        ("FV", "Будущая стоимость"),
                        ("PMT", "Регулярный платеж"),
                        ("P, r, n, t", "См. основную формулу")
                    ]
                )
                
                FormulaSection(
                    title: "Реальная прибыль",
                    formula: "Real Return = Nominal Return / (1 + Inflation Rate)^t",
                    description: "Корректировка прибыли с учетом инфляции.",
                    variables: [
                        ("t", "Время в годах"),
                        ("Inflation Rate", "Годовая ставка инфляции")
                    ]
                )
            }
            .padding()
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Формулы")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FormulaSection: View {
    let title: String
    let formula: String
    let description: String
    let variables: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            
            Text(formula)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "00B4A5"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "00B4A5").opacity(0.1))
                )
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Переменные:")
                    .font(.system(size: 14, weight: .semibold))
                
                ForEach(variables, id: \.0) { variable in
                    HStack(spacing: 8) {
                        Text(variable.0)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "FFB300"))
                            .frame(width: 30, alignment: .leading)
                        
                        Text("–")
                            .foregroundColor(.secondary)
                        
                        Text(variable.1)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Фильтры")) {
                    Text("Функция в разработке")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: (URL) -> Void
        
        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onSelect(url)
        }
    }
}

//
//  Utilities.swift
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
