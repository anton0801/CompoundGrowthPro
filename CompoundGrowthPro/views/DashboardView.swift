import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showNewCalculation = false
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("dashboard_welcome".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("app_name".localized)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        QuickActionCard(
                            title: "dashboard_new_calculation".localized,
                            icon: "plus.circle.fill",
                            color: Color(hex: "00B4A5")
                        ) {
                            showNewCalculation = true
                        }
                        
                        QuickActionCard(
                            title: "dashboard_history".localized,
                            icon: "clock.fill",
                            color: Color(hex: "FFB300"),
                            badge: viewModel.calculations.count
                        ) {
                            selectedTab = 2
                        }
                        
                        QuickActionCard(
                            title: "tab_comparison".localized,
                            icon: "chart.bar.xaxis",
                            color: Color(hex: "4CAF50")
                        ) {
                            selectedTab = 3
                        }
                        
                        QuickActionCard(
                            title: "tab_goals".localized,
                            icon: "target",
                            color: Color(hex: "FF9800")
                        ) {
                            selectedTab = 1
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Calculations
                    if !viewModel.recentCalculations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("dashboard_recent".localized)
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
