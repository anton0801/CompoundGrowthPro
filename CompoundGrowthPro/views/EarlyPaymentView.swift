import SwiftUI

struct EarlyPaymentView: View {
    @StateObject private var viewModel = EarlyPaymentViewModel()
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Loan Details")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            CurrencyInputField(
                                title: "early_payment_loan_amount".localized,
                                value: $viewModel.loanPayment.loanAmount,
                                currency: .usd
                            )
                            
                            PercentageInputField(
                                title: "early_payment_interest_rate".localized,
                                value: $viewModel.loanPayment.interestRate
                            )
                            
                            SliderInputField(
                                title: "early_payment_term".localized,
                                value: Binding(
                                    get: { Double(viewModel.loanPayment.termMonths) },
                                    set: { viewModel.loanPayment.termMonths = Int($0) }
                                ),
                                range: 12...360,
                                step: 12
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Early Payment Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Early Payment Strategy")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            CurrencyInputField(
                                title: "early_payment_extra_payment".localized,
                                value: $viewModel.loanPayment.extraPayment,
                                currency: .usd
                            )
                            
                            PickerInputField(
                                title: "early_payment_frequency".localized,
                                selection: $viewModel.loanPayment.extraPaymentFrequency,
                                options: ExtraPaymentFrequency.allCases
                            )
                            
                            if viewModel.loanPayment.termMonths > 1 {
                                SliderInputField(
                                    title: "early_payment_start_month".localized,
                                    value: Binding(
                                        get: { Double(viewModel.loanPayment.startMonth) },
                                        set: { viewModel.loanPayment.startMonth = Int($0) }
                                    ),
                                    range: 1...Double(viewModel.loanPayment.termMonths),
                                    step: 1
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("early_payment_strategy".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    StrategyButton(
                                        title: "early_payment_reduce_term".localized,
                                        icon: "calendar.badge.minus",
                                        isSelected: viewModel.loanPayment.strategy == .reduceTerm
                                    ) {
                                        viewModel.loanPayment.strategy = .reduceTerm
                                    }
                                    
                                    StrategyButton(
                                        title: "early_payment_reduce_payment".localized,
                                        icon: "dollarsign.circle",
                                        isSelected: viewModel.loanPayment.strategy == .reducePayment
                                    ) {
                                        viewModel.loanPayment.strategy = .reducePayment
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Calculate Button
                    Button(action: {
                        viewModel.calculate()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showResults = true
                        }
                    }) {
                        HStack {
                            if viewModel.isCalculating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("early_payment_calculate".localized)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FF9800"),
                                    Color(hex: "F57C00")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Color(hex: "FF9800").opacity(0.4), radius: 20, x: 0, y: 10)
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
                    
                    // Results Section
                    if showResults, let result = viewModel.loanPayment.result {
                        EarlyPaymentResultsView(
                            result: result,
                            strategy: viewModel.loanPayment.strategy
                        )
                        .transition(.opacity.combined(with: .scale))
                        
                        // Compare Strategies Button
                        Button(action: {
                            viewModel.compareStrategies()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("early_payment_comparison".localized)
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
            .navigationTitle("early_payment_title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showStrategyComparison) {
            if let alternative = viewModel.alternativeResult,
               let current = viewModel.loanPayment.result {
                StrategyComparisonView(
                    currentResult: current,
                    currentStrategy: viewModel.loanPayment.strategy,
                    alternativeResult: alternative,
                    alternativeStrategy: viewModel.loanPayment.strategy == .reduceTerm ? .reducePayment : .reduceTerm
                )
            }
        }
    }
}

struct StrategyButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? .white : Color(hex: "FF9800"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FF9800") : Color(hex: "FF9800").opacity(0.1))
            )
        }
    }
}

struct EarlyPaymentResultsView: View {
    let result: EarlyPaymentResult
    let strategy: PaymentStrategy
    
    var body: some View {
        VStack(spacing: 20) {
            Text("early_payment_results".localized)
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Summary Cards
            VStack(spacing: 12) {
                ResultSummaryCard(
                    title: "early_payment_savings".localized,
                    value: formatCurrency(result.interestSavings, currency: .usd),
                    subtitle: String(format: "%.1f%% savings", (result.interestSavings / result.originalTotalInterest) * 100),
                    icon: "dollarsign.circle.fill",
                    color: Color(hex: "4CAF50")
                )
                .padding(.horizontal)
                
                if strategy == .reduceTerm {
                    ResultSummaryCard(
                        title: "early_payment_time_saved".localized,
                        value: "\(result.timeSavedMonths) months",
                        subtitle: String(format: "%.1f years earlier", Double(result.timeSavedMonths) / 12.0),
                        icon: "clock.fill",
                        color: Color(hex: "FFB300")
                    )
                    .padding(.horizontal)
                } else {
                    ResultSummaryCard(
                        title: "early_payment_new_payment".localized,
                        value: formatCurrency(result.newMonthlyPayment, currency: .usd),
                        subtitle: String(format: "Save %@ per month", formatCurrency(result.originalMonthlyPayment - result.newMonthlyPayment, currency: .usd)),
                        icon: "arrow.down.circle.fill",
                        color: Color(hex: "00B4A5")
                    )
                    .padding(.horizontal)
                }
            }
            
            // Comparison Chart
            VStack(alignment: .leading, spacing: 16) {
                Text("early_payment_chart".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal)
                
                PaymentComparisonChart(result: result)
                    .frame(height: 250)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
            }
            
            // Detailed Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Detailed Comparison")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    ComparisonRow(
                        title: "Original Monthly Payment",
                        original: formatCurrency(result.originalMonthlyPayment, currency: .usd),
                        new: formatCurrency(result.newMonthlyPayment, currency: .usd)
                    )
                    
                    Divider()
                    
                    ComparisonRow(
                        title: "Loan Term",
                        original: "\(result.originalTotalInterest > 0 ? Int(result.originalTotalPaid / result.originalMonthlyPayment) : 0) months",
                        new: "\(result.newTermMonths) months"
                    )
                    
                    Divider()
                    
                    ComparisonRow(
                        title: "Total Interest",
                        original: formatCurrency(result.originalTotalInterest, currency: .usd),
                        new: formatCurrency(result.newTotalInterest, currency: .usd)
                    )
                    
                    Divider()
                    
                    ComparisonRow(
                        title: "Total Paid",
                        original: formatCurrency(result.originalTotalPaid, currency: .usd),
                        new: formatCurrency(result.newTotalPaid, currency: .usd)
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
            }
        }
    }
}

struct ResultSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PaymentComparisonChart: View {
    let result: EarlyPaymentResult
    
    var body: some View {
        GeometryReader { geometry in
            let originalMonths = result.originalTotalPaid > 0 ? Int(result.originalTotalPaid / result.originalMonthlyPayment) : 0
            let newMonths = result.newTermMonths
            let maxMonths = max(originalMonths, newMonths)
            
            HStack(alignment: .bottom, spacing: 40) {
                // Original loan bar
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.6),
                                    Color.gray.opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(originalMonths) / CGFloat(maxMonths) * geometry.size.height * 0.8)
                    
                    VStack(spacing: 4) {
                        Text("early_payment_without_extra".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(originalMonths) mo")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // New loan bar with early payment
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "4CAF50"),
                                    Color(hex: "66BB6A")
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(newMonths) / CGFloat(maxMonths) * geometry.size.height * 0.8)
                    
                    VStack(spacing: 4) {
                        Text("early_payment_with_extra".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(newMonths) mo")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ComparisonRow: View {
    let title: String
    let original: String
    let new: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Original")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(original)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("With Early Payment")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(new)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "4CAF50"))
                }
            }
        }
        .padding()
    }
}

struct StrategyComparisonView: View {
    let currentResult: EarlyPaymentResult
    let currentStrategy: PaymentStrategy
    let alternativeResult: EarlyPaymentResult
    let alternativeStrategy: PaymentStrategy
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Compare which strategy works best for you")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    HStack(spacing: 16) {
                        StrategyComparisonCard(
                            strategy: currentStrategy,
                            result: currentResult,
                            isRecommended: currentResult.totalSaved > alternativeResult.totalSaved
                        )
                        
                        StrategyComparisonCard(
                            strategy: alternativeStrategy,
                            result: alternativeResult,
                            isRecommended: alternativeResult.totalSaved > currentResult.totalSaved
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recommendation
                    let optimal = currentResult.totalSaved > alternativeResult.totalSaved ? currentStrategy : alternativeStrategy
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "FFB300"))
                            
                            Text("early_payment_optimal".localized)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Spacer()
                        }
                        
                        Text(optimal == .reduceTerm
                             ? "Reducing the loan term will save you more in interest over time, making it the better choice if you can afford the current payment amount."
                             : "Reducing your monthly payment provides immediate cash flow relief, which can be beneficial if you need flexibility in your monthly budget.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "FFB300").opacity(0.1))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("early_payment_comparison".localized)
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

struct StrategyComparisonCard: View {
    let strategy: PaymentStrategy
    let result: EarlyPaymentResult
    let isRecommended: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if isRecommended {
                HStack {
                    Spacer()
                    Text("Recommended")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "4CAF50"))
                        )
                }
            }
            
            VStack(spacing: 8) {
                Image(systemName: strategy == .reduceTerm ? "calendar.badge.minus" : "dollarsign.circle")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "FF9800"))
                
                Text(strategy.localizedString)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                MetricRow(title: "Total Savings", value: formatCurrency(result.totalSaved, currency: .usd), icon: "arrow.down.circle.fill",
                          color: Color(hex: "FF9800"))
                
                if strategy == .reduceTerm {
                    MetricRow(title: "Time Saved", value: "\(result.timeSavedMonths) months", icon: "arrow.down.circle.fill",
                              color: Color(hex: "FF9800"))
                    MetricRow(title: "New Term", value: "\(result.newTermMonths) months", icon: "arrow.down.circle.fill",
                              color: Color(hex: "FF9800"))
                } else {
                    MetricRow(title: "New Payment", value: formatCurrency(result.newMonthlyPayment, currency: .usd), icon: "arrow.down.circle.fill",
                              color: Color(hex: "FF9800"))
                    MetricRow(title: "Monthly Savings", value: formatCurrency(result.originalMonthlyPayment - result.newMonthlyPayment, currency: .usd), icon: "arrow.down.circle.fill",
                              color: Color(hex: "FF9800"))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isRecommended ? Color(hex: "4CAF50") : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

//struct MetricRow: View {
//    let label: String
//    let value: String
//    
//    var body: some View {
//        HStack {
//            Text(label)
//                .font(.system(size: 13))
//                .foregroundColor(.secondary)
//            
//            Spacer()
//            
//            Text(value)
//                .font(.system(size: 14, weight: .semibold, design: .rounded))
//                .foregroundColor(.primary)
//        }
//    }
//}
