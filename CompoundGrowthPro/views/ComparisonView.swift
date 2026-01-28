import SwiftUI

struct ComparisonView: View {
    @StateObject private var viewModel = ComparisonViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.selectedScenarios.isEmpty {
                    EmptyComparisonView(viewModel: viewModel)
                } else {
                    // Selected scenarios chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedScenarios) { scenario in
                                ScenarioChip(scenario: scenario) {
                                    viewModel.removeScenario(scenario)
                                }
                            }
                            
                            if viewModel.selectedScenarios.count < 5 {
                                AddScenarioButton {
                                    viewModel.showingCalculationPicker = true
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        ComparisonTabButton(title: "comparison_overlay".localized, icon: "chart.xyaxis.line", isSelected: selectedTab == 0) {
                            withAnimation { selectedTab = 0 }
                        }
                        ComparisonTabButton(title: "comparison_table".localized, icon: "tablecells", isSelected: selectedTab == 1) {
                            withAnimation { selectedTab = 1 }
                        }
                        ComparisonTabButton(title: "comparison_metrics".localized, icon: "chart.bar.fill", isSelected: selectedTab == 2) {
                            withAnimation { selectedTab = 2 }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        ComparisonChartTab(viewModel: viewModel)
                            .tag(0)
                        
                        ComparisonTableTab(viewModel: viewModel)
                            .tag(1)
                        
                        ComparisonMetricsTab(viewModel: viewModel)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("comparison_title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showingCalculationPicker) {
            CalculationPickerView(viewModel: viewModel)
        }
    }
}

struct EmptyComparisonView: View {
    @ObservedObject var viewModel: ComparisonViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "00B4A5").opacity(0.3))
            
            VStack(spacing: 12) {
                Text("comparison_empty".localized)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("comparison_empty_desc".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                viewModel.showingCalculationPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("comparison_add".localized)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
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
                .cornerRadius(25)
                .shadow(color: Color(hex: "00B4A5").opacity(0.3), radius: 15, x: 0, y: 8)
            }
        }
    }
}

struct ScenarioChip: View {
    let scenario: ComparisonScenario
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: scenario.color))
                .frame(width: 12, height: 12)
            
            Text(scenario.calculation.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: scenario.color).opacity(0.1))
        )
    }
}

struct AddScenarioButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("comparison_add".localized)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Color(hex: "00B4A5"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(Color(hex: "00B4A5"), lineWidth: 1.5)
            )
        }
    }
}

struct ComparisonTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
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

// MARK: - Chart Tab
struct ComparisonChartTab: View {
    @ObservedObject var viewModel: ComparisonViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let result = viewModel.comparisonResult {
                    // Overlay Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("comparison_chart_title".localized)
                            .font(.system(size: 18, weight: .semibold))
                        
                        ComparisonOverlayChart(result: result)
                            .frame(height: 300)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Best/Worst Analysis
                    VStack(spacing: 16) {
                        BestWorstCard(
                            title: "comparison_best".localized,
                            scenario: result.bestScenario,
                            isBest: true
                        )
                        
                        BestWorstCard(
                            title: "comparison_worst".localized,
                            scenario: result.worstScenario,
                            isBest: false
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ComparisonOverlayChart: View {
    let result: ComparisonResult
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid
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
                
                // Lines for each scenario
                ForEach(result.scenarios) { scenario in
                    if let yearlyData = scenario.calculation.result?.yearlyBreakdown {
                        ScenarioLine(
                            data: yearlyData,
                            color: Color(hex: scenario.color),
                            maxValue: result.metrics.maxFinalAmount,
                            geometry: geometry
                        )
                    }
                }
            }
        }
    }
}

struct ScenarioLine: View {
    let data: [YearData]
    let color: Color
    let maxValue: Double
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            guard !data.isEmpty else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(data.count - 1)
            
            path.move(to: CGPoint(
                x: 0,
                y: height - (CGFloat(data[0].balance / maxValue) * height)
            ))
            
            for (index, item) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let y = height - (CGFloat(item.balance / maxValue) * height)
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

struct BestWorstCard: View {
    let title: String
    let scenario: ComparisonScenario
    let isBest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isBest ? "crown.fill" : "flag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isBest ? Color(hex: "FFB300") : .secondary)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: scenario.color))
                    .frame(width: 12, height: 12)
                
                Text(scenario.calculation.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            if let result = scenario.calculation.result {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("result_final_amount".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.finalAmount, currency: scenario.calculation.currency))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("result_profit".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(result.totalInterest, currency: scenario.calculation.currency))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FFB300"))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: scenario.color), lineWidth: 2)
                )
        )
    }
}

// MARK: - Table Tab
struct ComparisonTableTab: View {
    @ObservedObject var viewModel: ComparisonViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let result = viewModel.comparisonResult {
                    // Header
                    HStack(spacing: 0) {
                        Text("Scenario")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .leading)
                        
                        Text("Final")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("Profit")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("ROI")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    // Rows
                    ForEach(result.scenarios) { scenario in
                        ComparisonTableRow(scenario: scenario)
                        Divider()
                    }
                    
                    // Average row
                    HStack(spacing: 0) {
                        Text("comparison_average".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 120, alignment: .leading)
                        
                        Text(formatCurrency(result.averageFinalAmount, currency: .usd))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                        
                        Text("-")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                        
                        Text(String(format: "%.1f%%", result.metrics.averageROI))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(hex: "00B4A5").opacity(0.1))
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ComparisonTableRow: View {
    let scenario: ComparisonScenario
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: scenario.color))
                    .frame(width: 10, height: 10)
                
                Text(scenario.calculation.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }
            .frame(width: 120, alignment: .leading)
            
            if let result = scenario.calculation.result {
                Text(formatCurrency(result.finalAmount, currency: scenario.calculation.currency))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                
                Text(formatCurrency(result.totalInterest, currency: scenario.calculation.currency))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                
                let roi = (result.totalInterest / result.totalContributions) * 100
                Text(String(format: "%.1f%%", roi))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(roi > 0 ? Color(hex: "4CAF50") : .red)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

// MARK: - Metrics Tab
struct ComparisonMetricsTab: View {
    @ObservedObject var viewModel: ComparisonViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let result = viewModel.comparisonResult {
                    MetricCard(
                        title: "Maximum Final Amount",
                        value: formatCurrency(result.metrics.maxFinalAmount, currency: .usd),
                        icon: "arrow.up.circle.fill",
                        color: Color(hex: "4CAF50")
                    )
                    
                    MetricCard(
                        title: "Minimum Final Amount",
                        value: formatCurrency(result.metrics.minFinalAmount, currency: .usd),
                        icon: "arrow.down.circle.fill",
                        color: Color(hex: "FF9800")
                    )
                    
                    MetricCard(
                        title: "comparison_difference".localized,
                        value: formatCurrency(result.metrics.maxFinalAmount - result.metrics.minFinalAmount, currency: .usd),
                        icon: "minus.circle.fill",
                        color: Color(hex: "00B4A5")
                    )
                    
                    Divider()
                        .padding(.vertical)
                    
                    MetricCard(
                        title: "Maximum ROI",
                        value: String(format: "%.2f%%", result.metrics.maxROI),
                        icon: "chart.line.uptrend.xyaxis",
                        color: Color(hex: "4CAF50")
                    )
                    
                    MetricCard(
                        title: "Minimum ROI",
                        value: String(format: "%.2f%%", result.metrics.minROI),
                        icon: "chart.line.downtrend.xyaxis",
                        color: Color(hex: "F44336")
                    )
                    
                    MetricCard(
                        title: "Average ROI",
                        value: String(format: "%.2f%%", result.metrics.averageROI),
                        icon: "equal.circle.fill",
                        color: Color(hex: "FFB300")
                    )
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Calculation Picker
struct CalculationPickerView: View {
    @ObservedObject var viewModel: ComparisonViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.availableCalculations) { calculation in
                    Button(action: {
                        viewModel.addScenario(calculation)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(calculation.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                if let result = calculation.result {
                                    Text(formatCurrency(result.finalAmount, currency: calculation.currency))
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(Color(hex: "4CAF50"))
                                }
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedScenarios.contains(where: { $0.calculation.id == calculation.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "00B4A5"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(viewModel.selectedScenarios.contains(where: { $0.calculation.id == calculation.id }))
                }
            }
            .navigationTitle("comparison_select".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}
