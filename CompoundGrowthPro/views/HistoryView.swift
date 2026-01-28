import SwiftUI

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
            
            TextField("history_search".localized, text: $text)
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
