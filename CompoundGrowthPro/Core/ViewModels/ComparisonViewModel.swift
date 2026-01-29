import Foundation
import Combine

class ComparisonViewModel: ObservableObject {
    @Published var availableCalculations: [Calculation] = []
    @Published var selectedScenarios: [ComparisonScenario] = []
    @Published var comparisonResult: ComparisonResult?
    @Published var showingCalculationPicker = false
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    private let scenarioColors = [
        "00B4A5", "FFB300", "4CAF50", "FF9800", "E91E63"
    ]
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        
        // Subscribe to calculations changes
        setupSubscriptions()
        
        // Initial load
        loadCalculations()
    }
    
    private func setupSubscriptions() {
        dataManager.$calculations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCalculations in
                self?.availableCalculations = newCalculations.filter { $0.result != nil }
            }
            .store(in: &cancellables)
    }
    
    func loadCalculations() {
        availableCalculations = dataManager.calculations.filter { $0.result != nil }
    }
    
    func addScenario(_ calculation: Calculation) {
        guard selectedScenarios.count < 5 else { return }
        
        let colorIndex = selectedScenarios.count % scenarioColors.count
        let scenario = ComparisonScenario(
            calculation: calculation,
            color: scenarioColors[colorIndex],
            isSelected: true
        )
        selectedScenarios.append(scenario)
        
        if selectedScenarios.count >= 2 {
            performComparison()
        }
    }
    
    func removeScenario(_ scenario: ComparisonScenario) {
        selectedScenarios.removeAll { $0.id == scenario.id }
        
        if selectedScenarios.count >= 2 {
            performComparison()
        } else {
            comparisonResult = nil
        }
    }
    
    func performComparison() {
        guard selectedScenarios.count >= 2 else { return }
        
        // Find best and worst scenarios
        let sortedByFinalAmount = selectedScenarios.sorted {
            ($0.calculation.result?.finalAmount ?? 0) > ($1.calculation.result?.finalAmount ?? 0)
        }
        
        guard let best = sortedByFinalAmount.first,
              let worst = sortedByFinalAmount.last else { return }
        
        // Calculate metrics
        let finalAmounts = selectedScenarios.compactMap { $0.calculation.result?.finalAmount }
        let profits = selectedScenarios.compactMap { $0.calculation.result?.totalInterest }
        
        let rois = selectedScenarios.compactMap { scenario -> Double? in
            guard let result = scenario.calculation.result,
                  result.totalContributions > 0 else { return nil }
            return (result.totalInterest / result.totalContributions) * 100
        }
        
        let metrics = ComparisonMetrics(
            maxFinalAmount: finalAmounts.max() ?? 0,
            minFinalAmount: finalAmounts.min() ?? 0,
            maxProfit: profits.max() ?? 0,
            minProfit: profits.min() ?? 0,
            maxROI: rois.max() ?? 0,
            minROI: rois.min() ?? 0,
            averageROI: rois.isEmpty ? 0 : rois.reduce(0, +) / Double(rois.count)
        )
        
        let avgFinalAmount = finalAmounts.isEmpty ? 0 : finalAmounts.reduce(0, +) / Double(finalAmounts.count)
        
        comparisonResult = ComparisonResult(
            scenarios: selectedScenarios,
            bestScenario: best,
            worstScenario: worst,
            averageFinalAmount: avgFinalAmount,
            metrics: metrics
        )
    }
    
    func exportComparison() -> URL? {
        guard let result = comparisonResult else { return nil }
        
        // Create PDF or CSV export
        // Implementation would go here
        
        return nil
    }
    
}
