import Foundation
import Combine

class EarlyPaymentViewModel: ObservableObject {
    @Published var loanPayment: LoanPayment
    @Published var isCalculating = false
    @Published var errorMessage: String?
    @Published var showStrategyComparison = false
    @Published var alternativeResult: EarlyPaymentResult?
    
    private let dataManager: DataManager
    
    init(loanPayment: LoanPayment? = nil, dataManager: DataManager = .shared) {
        self.loanPayment = loanPayment ?? LoanPayment(
            loanAmount: 0,
            interestRate: 0,
            termMonths: 0,
            extraPayment: 0,
            extraPaymentFrequency: .monthly,
            startMonth: 1,
            strategy: .reduceTerm
        )
        self.dataManager = dataManager
    }
    
    func calculate() {
        isCalculating = true
        errorMessage = nil
        
        guard validateInputs() else {
            isCalculating = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.calculateEarlyPayment()
            
            DispatchQueue.main.async {
                self.loanPayment.result = result
                self.isCalculating = false
            }
        }
    }
    
    func compareStrategies() {
        guard loanPayment.result != nil else { return }
        
        // Calculate alternative strategy
        let alternativeStrategy: PaymentStrategy = loanPayment.strategy == .reduceTerm ? .reducePayment : .reduceTerm
        
        var alternativeLoan = loanPayment
        alternativeLoan.strategy = alternativeStrategy
        
        let viewModel = EarlyPaymentViewModel(loanPayment: alternativeLoan)
        alternativeResult = viewModel.calculateEarlyPayment()
        showStrategyComparison = true
    }
    
    private func validateInputs() -> Bool {
        if loanPayment.loanAmount <= 0 {
            errorMessage = "error_principal_positive".localized
            return false
        }
        
        if loanPayment.interestRate <= 0 {
            errorMessage = "error_rate_positive".localized
            return false
        }
        
        if loanPayment.termMonths <= 0 {
            errorMessage = "error_time_positive".localized
            return false
        }
        
        if loanPayment.extraPayment < 0 {
            errorMessage = "error_invalid_input".localized
            return false
        }
        
        return true
    }
    
    private func calculateEarlyPayment() -> EarlyPaymentResult {
        let principal = loanPayment.loanAmount
        let monthlyRate = loanPayment.interestRate / 100.0 / 12.0
        let originalTerm = loanPayment.termMonths
        
        // Calculate original loan details
        let originalMonthlyPayment = calculateMonthlyPayment(
            principal: principal,
            monthlyRate: monthlyRate,
            months: originalTerm
        )
        
        var originalSchedule = generatePaymentSchedule(
            principal: principal,
            monthlyPayment: originalMonthlyPayment,
            monthlyRate: monthlyRate,
            months: originalTerm,
            extraPayment: 0,
            startMonth: 0,
            frequency: .monthly
        )
        
        let originalTotalPaid = originalSchedule.reduce(0) { $0 + $1.payment }
        let originalTotalInterest = originalTotalPaid - principal
        
        // Calculate with early payments
        var newSchedule: [MonthlyPaymentData]
        var newMonthlyPayment = originalMonthlyPayment
        var newTerm = originalTerm
        
        switch loanPayment.strategy {
        case .reduceTerm:
            // Keep payment same, reduce term
            newSchedule = generatePaymentSchedule(
                principal: principal,
                monthlyPayment: originalMonthlyPayment,
                monthlyRate: monthlyRate,
                months: originalTerm,
                extraPayment: loanPayment.extraPayment,
                startMonth: loanPayment.startMonth,
                frequency: loanPayment.extraPaymentFrequency
            )
            newTerm = newSchedule.count
            
        case .reducePayment:
            // Reduce payment, keep term same
            let totalWithExtra = calculateTotalWithExtraPayments(
                principal: principal,
                monthlyRate: monthlyRate,
                originalPayment: originalMonthlyPayment,
                extraPayment: loanPayment.extraPayment,
                startMonth: loanPayment.startMonth,
                frequency: loanPayment.extraPaymentFrequency,
                months: originalTerm
            )
            
            newMonthlyPayment = calculateReducedPayment(
                principal: principal,
                monthlyRate: monthlyRate,
                months: originalTerm,
                extraPayment: loanPayment.extraPayment,
                frequency: loanPayment.extraPaymentFrequency
            )
            
            newSchedule = generatePaymentSchedule(
                principal: principal,
                monthlyPayment: newMonthlyPayment,
                monthlyRate: monthlyRate,
                months: originalTerm,
                extraPayment: loanPayment.extraPayment,
                startMonth: loanPayment.startMonth,
                frequency: loanPayment.extraPaymentFrequency
            )
        }
        
        let newTotalPaid = newSchedule.reduce(0) { $0 + $1.payment + $1.extraPayment }
        let newTotalInterest = newTotalPaid - principal
        let interestSavings = originalTotalInterest - newTotalInterest
        let timeSaved = originalTerm - newTerm
        
        return EarlyPaymentResult(
            originalMonthlyPayment: originalMonthlyPayment,
            originalTotalInterest: originalTotalInterest,
            originalTotalPaid: originalTotalPaid,
            newTermMonths: newTerm,
            newMonthlyPayment: newMonthlyPayment,
            newTotalInterest: newTotalInterest,
            newTotalPaid: newTotalPaid,
            interestSavings: interestSavings,
            timeSavedMonths: timeSaved,
            totalSaved: interestSavings,
            paymentSchedule: newSchedule
        )
    }
    
    private func calculateMonthlyPayment(principal: Double, monthlyRate: Double, months: Int) -> Double {
        if monthlyRate == 0 {
            return principal / Double(months)
        }
        
        let rate = monthlyRate
        let numPayments = Double(months)
        
        return principal * (rate * pow(1 + rate, numPayments)) / (pow(1 + rate, numPayments) - 1)
    }
    
    private func generatePaymentSchedule(
        principal: Double,
        monthlyPayment: Double,
        monthlyRate: Double,
        months: Int,
        extraPayment: Double,
        startMonth: Int,
        frequency: ExtraPaymentFrequency
    ) -> [MonthlyPaymentData] {
        var schedule: [MonthlyPaymentData] = []
        var remainingBalance = principal
        var month = 1
        
        while remainingBalance > 0.01 && month <= months + 120 { // safety limit
            let interestPayment = remainingBalance * monthlyRate
            let principalPayment = min(monthlyPayment - interestPayment, remainingBalance)
            
            // Determine if extra payment applies this month
            var currentExtraPayment: Double = 0
            if month >= startMonth {
                switch frequency {
                case .monthly:
                    currentExtraPayment = extraPayment
                case .quarterly:
                    if (month - startMonth) % 3 == 0 {
                        currentExtraPayment = extraPayment
                    }
                case .annually:
                    if (month - startMonth) % 12 == 0 {
                        currentExtraPayment = extraPayment
                    }
                case .oneTime:
                    if month == startMonth {
                        currentExtraPayment = extraPayment
                    }
                }
            }
            
            currentExtraPayment = min(currentExtraPayment, remainingBalance - principalPayment)
            remainingBalance -= (principalPayment + currentExtraPayment)
            
            let data = MonthlyPaymentData(
                month: month,
                payment: monthlyPayment,
                principal: principalPayment,
                interest: interestPayment,
                extraPayment: currentExtraPayment,
                remainingBalance: max(0, remainingBalance)
            )
            
            schedule.append(data)
            month += 1
        }
        
        return schedule
    }
    
    private func calculateTotalWithExtraPayments(
        principal: Double,
        monthlyRate: Double,
        originalPayment: Double,
        extraPayment: Double,
        startMonth: Int,
        frequency: ExtraPaymentFrequency,
        months: Int
    ) -> Double {
        var balance = principal
        var total: Double = 0
        
        for month in 1...months {
            let interest = balance * monthlyRate
            let principalPmt = originalPayment - interest
            
            var extra: Double = 0
            if month >= startMonth {
                switch frequency {
                case .monthly:
                    extra = extraPayment
                case .quarterly:
                    if (month - startMonth) % 3 == 0 { extra = extraPayment }
                case .annually:
                    if (month - startMonth) % 12 == 0 { extra = extraPayment }
                case .oneTime:
                    if month == startMonth { extra = extraPayment }
                }
            }
            
            balance -= (principalPmt + extra)
            total += (originalPayment + extra)
            
            if balance <= 0 { break }
        }
        
        return total
    }
    
    private func calculateReducedPayment(
        principal: Double,
        monthlyRate: Double,
        months: Int,
        extraPayment: Double,
        frequency: ExtraPaymentFrequency
    ) -> Double {
        // Simplified calculation - in reality would need iterative approach
        let totalExtraPayments: Double
        
        switch frequency {
        case .monthly:
            totalExtraPayments = extraPayment * Double(months)
        case .quarterly:
            totalExtraPayments = extraPayment * Double(months / 3)
        case .annually:
            totalExtraPayments = extraPayment * Double(months / 12)
        case .oneTime:
            totalExtraPayments = extraPayment
        }
        
        let adjustedPrincipal = principal - totalExtraPayments
        return calculateMonthlyPayment(principal: adjustedPrincipal, monthlyRate: monthlyRate, months: months)
    }
    
    func saveLoanPayment() {
        // Save to data manager if needed
        // dataManager.saveLoanPayment(loanPayment)
    }
}
