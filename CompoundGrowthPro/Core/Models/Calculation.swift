import Foundation

struct Calculation: Identifiable, Codable {
    let id: UUID
    var name: String
    var principal: Double // начальная сумма
    var rate: Double // годовая ставка (в процентах)
    var time: Double // время в годах
    var compoundingFrequency: CompoundingFrequency
    var calculationType: CalculationType
    var regularContribution: Double // регулярные вклады
    var contributionFrequency: ContributionFrequency
    var inflationRate: Double // инфляция
    var taxRate: Double // налоговая ставка
    var currency: Currency
    var result: CalculationResult?
    var createdAt: Date
    var profileID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String = "Новый расчет",
        principal: Double = 0,
        rate: Double = 0,
        time: Double = 0,
        compoundingFrequency: CompoundingFrequency = .annually,
        calculationType: CalculationType = .compound,
        regularContribution: Double = 0,
        contributionFrequency: ContributionFrequency = .monthly,
        inflationRate: Double = 0,
        taxRate: Double = 0,
        currency: Currency = .rub,
        result: CalculationResult? = nil,
        createdAt: Date = Date(),
        profileID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.principal = principal
        self.rate = rate
        self.time = time
        self.compoundingFrequency = compoundingFrequency
        self.calculationType = calculationType
        self.regularContribution = regularContribution
        self.contributionFrequency = contributionFrequency
        self.inflationRate = inflationRate
        self.taxRate = taxRate
        self.currency = currency
        self.result = result
        self.createdAt = createdAt
        self.profileID = profileID
    }
}

struct RuntimeConfiguration {
    var resource: String?
    var behavior: String?
    var isFirstRun: Bool
    var alertsApproved: Bool
    var alertsRejected: Bool
    var lastAlertRequest: Date?
    
    var shouldRequestAlerts: Bool {
        guard !alertsApproved && !alertsRejected else {
            return false
        }
        
        if let lastRequest = lastAlertRequest {
            let elapsed = Date().timeIntervalSince(lastRequest) / 86400
            return elapsed >= 3
        }
        
        return true
    }
}


struct CalculationResult: Codable {
    let finalAmount: Double
    let totalInterest: Double
    let totalContributions: Double
    let realReturn: Double // с учетом инфляции
    let afterTaxReturn: Double // после налогов
    let yearlyBreakdown: [YearData]
}

struct YearData: Codable, Identifiable {
    let id = UUID()
    let year: Double
    let balance: Double
    let interest: Double
    let contribution: Double
    
    enum CodingKeys: String, CodingKey {
        case year, balance, interest, contribution
    }
}

// MARK: - Enumerations
enum CompoundingFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiannually = "Semi-Annually"
    case annually = "Annually"
    
    var localizedString: String {
        switch self {
        case .daily: return "freq_daily".localized
        case .monthly: return "freq_monthly".localized
        case .quarterly: return "freq_quarterly".localized
        case .semiannually: return "freq_semiannually".localized
        case .annually: return "freq_annually".localized
        }
    }
    
    var value: Double {
        switch self {
        case .daily: return 365
        case .monthly: return 12
        case .quarterly: return 4
        case .semiannually: return 2
        case .annually: return 1
        }
    }
}

enum CalculationType: String, Codable, CaseIterable {
    case simple = "Simple Interest"
    case compound = "Compound Interest"
    case withContributions = "With Regular Contributions"
    case investment = "Investment"
    case loan = "Loan"
    case retirement = "Retirement"
    case savings = "Savings"
    
    var localizedString: String {
        switch self {
        case .simple: return "type_simple".localized
        case .compound: return "type_compound".localized
        case .withContributions: return "type_contributions".localized
        case .investment: return "type_investment".localized
        case .loan: return "type_loan".localized
        case .retirement: return "type_retirement".localized
        case .savings: return "type_savings".localized
        }
    }
}

enum ContributionFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    
    var localizedString: String {
        switch self {
        case .monthly: return "freq_monthly".localized
        case .quarterly: return "freq_quarterly".localized
        case .annually: return "freq_annually".localized
        }
    }
    
    var value: Double {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .annually: return 1
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var localizedString: String {
        switch self {
        case .light: return "theme_light".localized
        case .dark: return "theme_dark".localized
        case .system: return "theme_system".localized
        }
    }
}

struct MarketingContext {
    private let container: [String: Any]
    
    init(content: [String: Any]) {
        self.container = content
    }
    
    var isEmpty: Bool {
        container.isEmpty
    }
    
    var isNaturalSource: Bool {
        container["af_status"] as? String == "Organic"
    }
    
    func extract(key: String) -> Any? {
        container[key]
    }
    
    var content: [String: Any] {
        container
    }
}

enum Currency: String, Codable, CaseIterable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }
}

// MARK: - Profile Model
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var defaultCurrency: Currency
    var defaultInflationRate: Double
    var calculationIDs: [UUID]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        defaultCurrency: Currency = .rub,
        defaultInflationRate: Double = 0,
        calculationIDs: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultCurrency = defaultCurrency
        self.defaultInflationRate = defaultInflationRate
        self.calculationIDs = calculationIDs
        self.createdAt = createdAt
    }
}

enum RuntimePhase: Equatable {
    case dormant
    case awakening
    case checking
    case authorized
    case operational(resource: String)
    case paused
    case unavailable
}

struct AppSettings: Codable {
    var theme: AppTheme
    var defaultCurrency: Currency
    var notificationsEnabled: Bool
    var biometricAuthEnabled: Bool
    var currencyRates: [String: Double]
    
    init(
        theme: AppTheme = .system,
        defaultCurrency: Currency = .rub,
        notificationsEnabled: Bool = false,
        biometricAuthEnabled: Bool = false,
        currencyRates: [String: Double] = ["USD": 1.0, "EUR": 1.1, "GBP": 1.3, "RUB": 0.011]
    ) {
        self.theme = theme
        self.defaultCurrency = defaultCurrency
        self.notificationsEnabled = notificationsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.currencyRates = currencyRates
    }
}

// MARK: - Currency Rates
struct CurrencyRates: Codable {
    var rates: [String: Double]
    var lastUpdated: Date
    
    init(rates: [String: Double] = [:], lastUpdated: Date = Date()) {
        self.rates = rates
        self.lastUpdated = lastUpdated
    }
}

struct ComparisonScenario: Identifiable {
    let id = UUID()
    let calculation: Calculation
    var color: String
    var isSelected: Bool = false
}

struct ComparisonResult {
    let scenarios: [ComparisonScenario]
    let bestScenario: ComparisonScenario
    let worstScenario: ComparisonScenario
    let averageFinalAmount: Double
    let metrics: ComparisonMetrics
}

struct ComparisonMetrics {
    let maxFinalAmount: Double
    let minFinalAmount: Double
    let maxProfit: Double
    let minProfit: Double
    let maxROI: Double
    let minROI: Double
    let averageROI: Double
}

struct NavigationContext {
    private let container: [String: Any]
    
    init(content: [String: Any]) {
        self.container = content
    }
    
    var isEmpty: Bool {
        container.isEmpty
    }
    
    func extract(key: String) -> Any? {
        container[key]
    }
    
    var content: [String: Any] {
        container
    }
}
