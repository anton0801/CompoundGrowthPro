import Foundation

struct FinancialGoal: Identifiable, Codable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date
    var category: GoalCategory
    var monthlyContribution: Double
    var currency: Currency
    var notifyOnMilestones: Bool
    var notifyBeforeDeadline: Bool
    var contributions: [Contribution]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date,
        category: GoalCategory,
        monthlyContribution: Double = 0,
        currency: Currency = .usd,
        notifyOnMilestones: Bool = true,
        notifyBeforeDeadline: Bool = true,
        contributions: [Contribution] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.category = category
        self.monthlyContribution = monthlyContribution
        self.currency = currency
        self.notifyOnMilestones = notifyOnMilestones
        self.notifyBeforeDeadline = notifyBeforeDeadline
        self.contributions = contributions
        self.createdAt = createdAt
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var progressPercentage: Double {
        return progress * 100
    }
    
    var isCompleted: Bool {
        return currentAmount >= targetAmount
    }
    
    var daysLeft: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: deadline)
        return components.day ?? 0
    }
    
    var monthsLeft: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month], from: now, to: deadline)
        return components.month ?? 0
    }
    
    var status: GoalStatus {
        if isCompleted {
            return .completed
        }
        
        let projectedCompletion = calculateProjectedCompletion()
        
        if projectedCompletion <= deadline {
            return .onTrack
        } else if projectedCompletion.timeIntervalSince(deadline) < 30 * 24 * 60 * 60 { // within 30 days
            return .slightlyBehind
        } else {
            return .behind
        }
    }
    
    var requiredMonthlyContribution: Double {
        guard targetAmount > currentAmount else { return 0 }
        let remaining = targetAmount - currentAmount
        let months = max(monthsLeft, 1)
        return remaining / Double(months)
    }
    
    func calculateProjectedCompletion() -> Date {
        guard monthlyContribution > 0 else {
            return deadline.addingTimeInterval(365 * 24 * 60 * 60) // далеко в будущем
        }
        
        let remaining = targetAmount - currentAmount
        let monthsNeeded = ceil(remaining / monthlyContribution)
        
        return Calendar.current.date(byAdding: .month, value: Int(monthsNeeded), to: Date()) ?? deadline
    }
    
    var milestones: [Milestone] {
        let percentages = [25.0, 50.0, 75.0, 90.0, 100.0]
        return percentages.map { percentage in
            let amount = targetAmount * (percentage / 100.0)
            let isPassed = currentAmount >= amount
            return Milestone(percentage: percentage, amount: amount, isPassed: isPassed)
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case home = "Home"
    case car = "Car"
    case education = "Education"
    case retirement = "Retirement"
    case emergency = "Emergency Fund"
    case vacation = "Vacation"
    case wedding = "Wedding"
    case other = "Other"
    
    var localizedString: String {
        switch self {
        case .home: return "goal_cat_home".localized
        case .car: return "goal_cat_car".localized
        case .education: return "goal_cat_education".localized
        case .retirement: return "goal_cat_retirement".localized
        case .emergency: return "goal_cat_emergency".localized
        case .vacation: return "goal_cat_vacation".localized
        case .wedding: return "goal_cat_wedding".localized
        case .other: return "goal_cat_other".localized
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .car: return "car.fill"
        case .education: return "book.fill"
        case .retirement: return "bed.double.fill"
        case .emergency: return "cross.case.fill"
        case .vacation: return "airplane"
        case .wedding: return "heart.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .home: return "FF6B6B"
        case .car: return "4ECDC4"
        case .education: return "45B7D1"
        case .retirement: return "F7DC6F"
        case .emergency: return "E74C3C"
        case .vacation: return "3498DB"
        case .wedding: return "E91E63"
        case .other: return "9B59B6"
        }
    }
}

enum GoalStatus {
    case onTrack
    case slightlyBehind
    case behind
    case completed
    
    var localizedString: String {
        switch self {
        case .onTrack: return "goals_on_track".localized
        case .slightlyBehind: return "goals_behind".localized
        case .behind: return "goals_behind".localized
        case .completed: return "goals_completed".localized
        }
    }
    
    var color: String {
        switch self {
        case .onTrack: return "4CAF50"
        case .slightlyBehind: return "FF9800"
        case .behind: return "F44336"
        case .completed: return "00B4A5"
        }
    }
}

struct Contribution: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var date: Date
    var note: String?
    
    init(id: UUID = UUID(), amount: Double, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct Milestone {
    let percentage: Double
    let amount: Double
    let isPassed: Bool
}
