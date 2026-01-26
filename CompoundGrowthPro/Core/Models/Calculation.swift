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

// MARK: - Calculation Result
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
    case daily = "Ежедневно"
    case monthly = "Ежемесячно"
    case quarterly = "Ежеквартально"
    case semiannually = "Раз в полгода"
    case annually = "Ежегодно"
    
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
    case simple = "Простой процент"
    case compound = "Сложный процент"
    case withContributions = "С регулярными вкладами"
    case investment = "Инвестиции"
    case loan = "Кредит"
    case retirement = "Пенсия"
    case savings = "Сбережения"
}

enum ContributionFrequency: String, Codable, CaseIterable {
    case monthly = "Ежемесячно"
    case quarterly = "Ежеквартально"
    case annually = "Ежегодно"
    
    var value: Double {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .annually: return 1
        }
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

// MARK: - Settings Model
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

enum AppTheme: String, Codable, CaseIterable {
    case light = "Светлая"
    case dark = "Темная"
    case system = "Системная"
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
