import Foundation

struct LoanPayment: Codable, Identifiable {
    let id = UUID()
    var loanAmount: Double
    var interestRate: Double // годовая ставка в процентах
    var termMonths: Int
    var extraPayment: Double
    var extraPaymentFrequency: ExtraPaymentFrequency
    var startMonth: Int
    var strategy: PaymentStrategy
    var result: EarlyPaymentResult?
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case loanAmount, interestRate, termMonths, extraPayment
        case extraPaymentFrequency, startMonth, strategy, result, createdAt
    }
}

enum ConnectorError: Error {
    case badPath
    case badResponse
    case decodeFailed
}

enum ExtraPaymentFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case oneTime = "One Time"
    
    var localizedString: String {
        switch self {
        case .monthly: return "freq_monthly".localized
        case .quarterly: return "freq_quarterly".localized
        case .annually: return "freq_annually".localized
        case .oneTime: return "One Time"
        }
    }
}

enum PaymentStrategy: String, Codable, CaseIterable {
    case reduceTerm = "Reduce Term"
    case reducePayment = "Reduce Payment"
    
    var localizedString: String {
        switch self {
        case .reduceTerm: return "early_payment_reduce_term".localized
        case .reducePayment: return "early_payment_reduce_payment".localized
        }
    }
}

struct EarlyPaymentResult: Codable {
    let originalMonthlyPayment: Double
    let originalTotalInterest: Double
    let originalTotalPaid: Double
    
    let newTermMonths: Int
    let newMonthlyPayment: Double
    let newTotalInterest: Double
    let newTotalPaid: Double
    
    let interestSavings: Double
    let timeSavedMonths: Int
    let totalSaved: Double
    
    let paymentSchedule: [MonthlyPaymentData]
}

struct MonthlyPaymentData: Codable, Identifiable {
    let id = UUID()
    let month: Int
    let payment: Double
    let principal: Double
    let interest: Double
    let extraPayment: Double
    let remainingBalance: Double
    
    enum CodingKeys: String, CodingKey {
        case month, payment, principal, interest, extraPayment, remainingBalance
    }
}
