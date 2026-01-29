import Foundation
import Combine

class GoalViewModel: ObservableObject {
    @Published var goal: FinancialGoal
    @Published var showAddContribution = false
    @Published var newContributionAmount: Double = 0
    @Published var newContributionDate: Date = Date()
    @Published var newContributionNote: String = ""
    
    private let dataManager: DataManager
    
    init(goal: FinancialGoal? = nil, dataManager: DataManager = .shared) {
        self.goal = goal ?? FinancialGoal(
            name: "",
            targetAmount: 0,
            deadline: Date().addingTimeInterval(365 * 24 * 60 * 60),
            category: .other
        )
        self.dataManager = dataManager
    }
    
    func addContribution() {
        let contribution = Contribution(
            amount: newContributionAmount,
            date: newContributionDate,
            note: newContributionNote.isEmpty ? nil : newContributionNote
        )
        
        goal.contributions.append(contribution)
        goal.currentAmount += newContributionAmount
        
        // Reset form
        newContributionAmount = 0
        newContributionDate = Date()
        newContributionNote = ""
        
        saveGoal()
        checkMilestones()
        
        // Haptic feedback
        HapticManager.shared.notification(type: .success)
    }
    
    func deleteContribution(_ contribution: Contribution) {
        goal.currentAmount -= contribution.amount
        goal.contributions.removeAll { $0.id == contribution.id }
        saveGoal()
    }
    
    func saveGoal() {
        dataManager.saveGoal(goal)
    }
    
    func deleteGoal() {
        dataManager.deleteGoal(goal)
    }
    
    private func checkMilestones() {
        guard goal.notifyOnMilestones else { return }
        
        let milestones = goal.milestones
        for milestone in milestones where milestone.isPassed {
            if goal.currentAmount >= milestone.amount && goal.currentAmount - newContributionAmount < milestone.amount {
                // Just crossed this milestone
                scheduleNotification(
                    title: "🎉 " + "Milestone Reached!",
                    body: String(format: "You've reached %.0f%% of your goal: %@", milestone.percentage, goal.name)
                )
            }
        }
        
        // Check if goal completed
        if goal.isCompleted && goal.currentAmount - newContributionAmount < goal.targetAmount {
            scheduleNotification(
                title: "🎊 " + "Goal Completed!",
                body: String(format: "Congratulations! You've reached your goal: %@", goal.name)
            )
        }
    }
    
    private func scheduleNotification(title: String, body: String) {
        NotificationManager.shared.scheduleReminder(
            title: title,
            body: body,
            date: Date().addingTimeInterval(1)
        )
    }
    
    func scheduleDeadlineReminder() {
        guard goal.notifyBeforeDeadline else { return }
        
        let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: goal.deadline) ?? goal.deadline
        
        NotificationManager.shared.scheduleReminder(
            title: "⏰ Goal Deadline Approaching",
            body: String(format: "Your goal '%@' is due in 7 days", goal.name),
            date: reminderDate
        )
    }
}

