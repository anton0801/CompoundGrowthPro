import Foundation
import Combine

class CalculatorViewModel: ObservableObject {
    @Published var calculation: Calculation
    @Published var isCalculating = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    
    init(calculation: Calculation? = nil, dataManager: DataManager = .shared) {
        self.calculation = calculation ?? Calculation()
        self.dataManager = dataManager
    }
    
    // MARK: - Calculate
    func calculate() {
        isCalculating = true
        errorMessage = nil
        
        // Validation
        guard validateInputs() else {
            isCalculating = false
            return
        }
        
        // Perform calculation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.performCalculation()
            
            DispatchQueue.main.async {
                self.calculation.result = result
                self.isCalculating = false
            }
        }
    }
    
    private func validateInputs() -> Bool {
        if calculation.principal < 0 {
            errorMessage = "Начальная сумма должна быть положительной"
            return false
        }
        
        if calculation.rate <= 0 {
            errorMessage = "Процентная ставка должна быть больше нуля"
            return false
        }
        
        if calculation.time <= 0 {
            errorMessage = "Период должен быть больше нуля"
            return false
        }
        
        return true
    }
    
    private func performCalculation() -> CalculationResult {
        let P = calculation.principal
        let r = calculation.rate / 100.0
        let t = calculation.time
        let n = calculation.compoundingFrequency.value
        let monthlyContribution = calculation.regularContribution
        let contributionsPerYear = calculation.contributionFrequency.value
        
        var yearlyBreakdown: [YearData] = []
        var totalContributions = P
        
        switch calculation.calculationType {
        case .simple:
            let A = P * (1 + r * t)
            let interest = A - P
            
            for year in 1...Int(t) {
                let balance = P * (1 + r * Double(year))
                let yearInterest = P * r
                yearlyBreakdown.append(YearData(year: Double(year), balance: balance, interest: yearInterest, contribution: 0))
            }
            
            return createResult(finalAmount: A, totalInterest: interest, totalContributions: P, yearlyBreakdown: yearlyBreakdown)
            
        case .compound, .investment, .savings:
            let A = P * pow(1 + r / n, n * t)
            let interest = A - P
            
            // Year-by-year breakdown
            for year in 1...Int(t) {
                let yearBalance = P * pow(1 + r / n, n * Double(year))
                let prevBalance = year > 1 ? P * pow(1 + r / n, n * Double(year - 1)) : P
                let yearInterest = yearBalance - prevBalance
                yearlyBreakdown.append(YearData(year: Double(year), balance: yearBalance, interest: yearInterest, contribution: 0))
            }
            
            return createResult(finalAmount: A, totalInterest: interest, totalContributions: P, yearlyBreakdown: yearlyBreakdown)
            
        case .withContributions, .retirement:
            var balance = P
            let periodsPerYear = n
            let contributionPerPeriod = monthlyContribution * (12.0 / contributionsPerYear) / periodsPerYear
            
            for year in 1...Int(t) {
                var yearStartBalance = balance
                var yearInterest = 0.0
                var yearContributions = 0.0
                
                for _ in 1...Int(periodsPerYear) {
                    let periodInterest = balance * (r / n)
                    balance += periodInterest + contributionPerPeriod
                    yearInterest += periodInterest
                    yearContributions += contributionPerPeriod
                }
                
                totalContributions += yearContributions
                yearlyBreakdown.append(YearData(
                    year: Double(year),
                    balance: balance,
                    interest: yearInterest,
                    contribution: yearContributions
                ))
            }
            
            let interest = balance - totalContributions
            return createResult(finalAmount: balance, totalInterest: interest, totalContributions: totalContributions, yearlyBreakdown: yearlyBreakdown)
            
        case .loan:
            // Loan calculation (амортизация)
            let monthlyRate = r / 12.0
            let numPayments = t * 12.0
            let monthlyPayment = P * (monthlyRate * pow(1 + monthlyRate, numPayments)) / (pow(1 + monthlyRate, numPayments) - 1)
            let totalPaid = monthlyPayment * numPayments
            let totalInterest = totalPaid - P
            
            var remainingBalance = P
            for year in 1...Int(t) {
                var yearInterest = 0.0
                var yearPrincipal = 0.0
                
                for _ in 1...12 {
                    let interestPayment = remainingBalance * monthlyRate
                    let principalPayment = monthlyPayment - interestPayment
                    remainingBalance -= principalPayment
                    yearInterest += interestPayment
                    yearPrincipal += principalPayment
                }
                
                yearlyBreakdown.append(YearData(
                    year: Double(year),
                    balance: max(0, remainingBalance),
                    interest: yearInterest,
                    contribution: yearPrincipal
                ))
            }
            
            return createResult(finalAmount: totalPaid, totalInterest: totalInterest, totalContributions: P, yearlyBreakdown: yearlyBreakdown)
        }
    }
    
    private func createResult(finalAmount: Double, totalInterest: Double, totalContributions: Double, yearlyBreakdown: [YearData]) -> CalculationResult {
        // Calculate with inflation
        let inflationRate = calculation.inflationRate / 100.0
        let realReturn = finalAmount / pow(1 + inflationRate, calculation.time)
        
        // Calculate after tax
        let taxRate = calculation.taxRate / 100.0
        let taxAmount = totalInterest * taxRate
        let afterTaxReturn = finalAmount - taxAmount
        
        return CalculationResult(
            finalAmount: finalAmount,
            totalInterest: totalInterest,
            totalContributions: totalContributions,
            realReturn: realReturn,
            afterTaxReturn: afterTaxReturn,
            yearlyBreakdown: yearlyBreakdown
        )
    }
    
    // MARK: - Save Calculation
    func saveCalculation() {
        dataManager.saveCalculation(calculation)
    }
    
    // MARK: - Reset
    func reset() {
        calculation = Calculation()
        errorMessage = nil
    }
}

//
//  DashboardViewModel.swift
//  CompoundGrowth Pro
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var calculations: [Calculation] = []
    @Published var profiles: [UserProfile] = []
    @Published var settings: AppSettings
    @Published var searchText = ""
    @Published var selectedProfile: UserProfile?
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    var filteredCalculations: [Calculation] {
        if searchText.isEmpty {
            if let profileID = selectedProfile?.id {
                return calculations.filter { $0.profileID == profileID }
            }
            return calculations
        } else {
            return calculations.filter { calculation in
                calculation.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var recentCalculations: [Calculation] {
        Array(calculations.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3))
    }
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        self.settings = dataManager.loadSettings()
        loadData()
    }
    
    func loadData() {
        calculations = dataManager.loadCalculations()
        profiles = dataManager.loadProfiles()
    }
    
    func deleteCalculation(_ calculation: Calculation) {
        dataManager.deleteCalculation(calculation)
        loadData()
    }
    
    func deleteProfile(_ profile: UserProfile) {
        dataManager.deleteProfile(profile)
        loadData()
    }
    
    func selectProfile(_ profile: UserProfile?) {
        selectedProfile = profile
    }
}

//
//  ProfileViewModel.swift
//  CompoundGrowth Pro
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var isNew: Bool
    
    private let dataManager: DataManager
    
    init(profile: UserProfile? = nil, dataManager: DataManager = .shared) {
        if let profile = profile {
            self.profile = profile
            self.isNew = false
        } else {
            self.profile = UserProfile(name: "Новый профиль")
            self.isNew = true
        }
        self.dataManager = dataManager
    }
    
    func save() {
        dataManager.saveProfile(profile)
    }
}

//
//  SettingsViewModel.swift
//  CompoundGrowth Pro
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var showExportSheet = false
    @Published var showImportSheet = false
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        self.settings = dataManager.loadSettings()
    }
    
    func saveSettings() {
        dataManager.saveSettings(settings)
    }
    
    func exportData() -> URL? {
        return dataManager.exportAllData()
    }
    
    func importData(from url: URL) -> Bool {
        return dataManager.importData(from: url)
    }
    
    func clearAllData() {
        dataManager.clearAllData()
        settings = AppSettings()
    }
}
