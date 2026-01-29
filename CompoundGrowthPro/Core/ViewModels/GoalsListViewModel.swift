import Foundation
import Combine

class GoalsListViewModel: ObservableObject {
    @Published var goals: [FinancialGoal] = []
    @Published var showCreateGoal = false
    @Published var selectedGoal: FinancialGoal?
    @Published var filterCategory: GoalCategory?
    @Published var sortOption: GoalSortOption = .deadline
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    enum GoalSortOption {
        case deadline
        case progress
        case amount
        case name
    }
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        
        // Subscribe to goals changes
        setupSubscriptions()
        
        // Initial load
        loadGoals()
    }
    
    private func setupSubscriptions() {
        // Subscribe to goals changes from DataManager
        dataManager.$goals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newGoals in
                self?.goals = newGoals
                self?.sortGoals()
            }
            .store(in: &cancellables)
        
        // Also listen to notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalsDidChange),
            name: .goalsDidChange,
            object: nil
        )
    }
    
    @objc private func goalsDidChange() {
        loadGoals()
    }
    
    func loadGoals() {
        goals = dataManager.goals
        sortGoals()
    }
    
    func deleteGoal(_ goal: FinancialGoal) {
        dataManager.deleteGoal(goal)
    }
    
    var filteredGoals: [FinancialGoal] {
        var filtered = goals
        
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    var activeGoals: [FinancialGoal] {
        filteredGoals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [FinancialGoal] {
        filteredGoals.filter { $0.isCompleted }
    }
    
    func sortGoals() {
        switch sortOption {
        case .deadline:
            goals.sort { $0.deadline < $1.deadline }
        case .progress:
            goals.sort { $0.progress > $1.progress }
        case .amount:
            goals.sort { $0.targetAmount > $1.targetAmount }
        case .name:
            goals.sort { $0.name < $1.name }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

