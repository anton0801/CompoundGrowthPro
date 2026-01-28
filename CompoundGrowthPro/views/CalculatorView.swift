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
                        Text("calc_type".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CalculationType.allCases, id: \.self) { type in
                                    TypeChip(
                                        title: type.localizedString,
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
                            title: "calc_principal".localized,
                            value: $viewModel.calculation.principal,
                            currency: viewModel.calculation.currency
                        )
                        
                        PercentageInputField(
                            title: "calc_rate".localized,
                            value: $viewModel.calculation.rate
                        )
                        
                        SliderInputField(
                            title: "calc_time".localized,
                            value: $viewModel.calculation.time,
                            range: 1...50,
                            step: 1
                        )
                        
                        PickerInputField(
                            title: "calc_frequency".localized,
                            selection: $viewModel.calculation.compoundingFrequency,
                            options: CompoundingFrequency.allCases
                        )
                        
                        if viewModel.calculation.calculationType == .withContributions ||
                           viewModel.calculation.calculationType == .retirement {
                            CurrencyInputField(
                                title: "calc_contributions".localized,
                                value: $viewModel.calculation.regularContribution,
                                currency: viewModel.calculation.currency
                            )
                            
                            PickerInputField(
                                title: "calc_contribution_freq".localized,
                                selection: $viewModel.calculation.contributionFrequency,
                                options: ContributionFrequency.allCases
                            )
                        }
                        
                        // Advanced Options
                        DisclosureGroup("calc_advanced".localized) {
                            VStack(spacing: 20) {
                                PercentageInputField(
                                    title: "calc_inflation".localized,
                                    value: $viewModel.calculation.inflationRate
                                )
                                
                                PercentageInputField(
                                    title: "calc_tax_rate".localized,
                                    value: $viewModel.calculation.taxRate
                                )
                                
                                PickerInputField(
                                    title: "calc_currency".localized,
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
                                Text("calc_calculate".localized)
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
                                Text("calc_save".localized)
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
            .navigationTitle("calc_title".localized)
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
            Text("calc_results".localized)
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ResultCard(
                title: "result_final_amount".localized,
                value: formatCurrency(result.finalAmount, currency: calculation.currency),
                color: Color(hex: "4CAF50"),
                icon: "chart.line.uptrend.xyaxis"
            )
            
            ResultCard(
                title: "result_profit".localized,
                value: formatCurrency(result.totalInterest, currency: calculation.currency),
                color: Color(hex: "FFB300"),
                icon: "dollarsign.circle.fill"
            )
            
            if calculation.inflationRate > 0 {
                ResultCard(
                    title: "result_real_return".localized,
                    value: formatCurrency(result.realReturn, currency: calculation.currency),
                    color: Color(hex: "FF9800"),
                    icon: "arrow.down.circle.fill"
                )
            }
            
            if calculation.taxRate > 0 {
                ResultCard(
                    title: "result_after_tax".localized,
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
                Section(header: Text("Calculation Name")) {
                    TextField("Enter name", text: $calculation.name)
                }
            }
            .navigationTitle("calc_save".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
