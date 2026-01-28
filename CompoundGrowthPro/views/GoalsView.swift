import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsListViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("", selection: $selectedSegment) {
                    Text("Active").tag(0)
                    Text("goals_completed".localized).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedSegment == 0 {
                    if viewModel.activeGoals.isEmpty {
                        EmptyGoalsView(viewModel: viewModel)
                    } else {
                        ActiveGoalsListView(viewModel: viewModel)
                    }
                } else {
                    if viewModel.completedGoals.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "No Completed Goals",
                            description: "Complete your first goal and it will appear here"
                        )
                    } else {
                        CompletedGoalsListView(viewModel: viewModel)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("goals_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showCreateGoal = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "00B4A5"))
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateGoal) {
            CreateGoalView {
                viewModel.loadGoals()
            }
        }
        .sheet(item: $viewModel.selectedGoal) { goal in
            GoalDetailView(goal: goal) {
                viewModel.loadGoals()
            }
        }
    }
}

struct EmptyGoalsView: View {
    @ObservedObject var viewModel: GoalsListViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "00B4A5").opacity(0.3))
            
            VStack(spacing: 12) {
                Text("goals_empty".localized)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("goals_empty_desc".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                viewModel.showCreateGoal = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("goals_create".localized)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "00B4A5"),
                            Color(hex: "00897B")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color(hex: "00B4A5").opacity(0.3), radius: 15, x: 0, y: 8)
            }
        }
    }
}

struct ActiveGoalsListView: View {
    @ObservedObject var viewModel: GoalsListViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.activeGoals) { goal in
                    GoalCard(goal: goal)
                        .padding(.horizontal)
                        .onTapGesture {
                            viewModel.selectedGoal = goal
                        }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100)
        }
    }
}

struct CompletedGoalsListView: View {
    @ObservedObject var viewModel: GoalsListViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.completedGoals) { goal in
                    CompletedGoalCard(goal: goal)
                        .padding(.horizontal)
                        .onTapGesture {
                            viewModel.selectedGoal = goal
                        }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100)
        }
    }
}

struct GoalCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: goal.category.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: goal.category.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(goal.category.localizedString)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: goal.status)
                    
                    if goal.daysLeft >= 0 {
                        Text(goal.daysLeft < 30
                             ? String(format: "goals_days_left".localized, goal.daysLeft)
                             : String(format: "goals_months_left".localized, goal.monthsLeft))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("goals_progress".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", goal.progressPercentage))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: goal.category.color))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: goal.category.color),
                                        Color(hex: goal.category.color).opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(goal.progress), height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: goal.progress)
                    }
                }
                .frame(height: 12)
            }
            
            // Amount Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(goal.currentAmount, currency: goal.currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(goal.targetAmount, currency: goal.currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: goal.category.color))
                }
            }
            
            // Milestones
            HStack(spacing: 8) {
                ForEach(goal.milestones, id: \.percentage) { milestone in
                    MilestoneIndicator(milestone: milestone, color: Color(hex: goal.category.color))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}

struct CompletedGoalCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "4CAF50"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatCurrency(goal.targetAmount, currency: goal.currency))
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(hex: "4CAF50"))
                
                Text("Completed on " + formatDate(goal.deadline))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "4CAF50").opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "4CAF50").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StatusBadge: View {
    let status: GoalStatus
    
    var body: some View {
        Text(status.localizedString)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: status.color))
            )
    }
}

struct MilestoneIndicator: View {
    let milestone: Milestone
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(milestone.isPassed ? color : Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                if milestone.isPassed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("\(Int(milestone.percentage))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(milestone.isPassed ? color : .secondary)
        }
    }
}

//
//  GoalDetailView.swift
//  CompoundGrowth Pro
//

struct GoalDetailView: View {
    @StateObject private var viewModel: GoalViewModel
    let onUpdate: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    
    init(goal: FinancialGoal, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: GoalViewModel(goal: goal))
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    GoalHeroSection(goal: viewModel.goal)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Roadmap
                    GoalRoadmapSection(goal: viewModel.goal)
                        .padding(.horizontal)
                    
                    // Progress Chart
                    GoalProgressChart(goal: viewModel.goal)
                        .padding(.horizontal)
                    
                    // Contribution History
                    ContributionHistorySection(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.showAddContribution = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("goals_add_contribution".localized)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: viewModel.goal.category.color),
                                        Color(hex: viewModel.goal.category.color).opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(hex: viewModel.goal.category.color).opacity(0.3), radius: 15, x: 0, y: 8)
                        }
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text("delete".localized)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        onUpdate()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddContribution) {
            AddContributionView(viewModel: viewModel)
        }
        .alert("goals_delete_confirm".localized, isPresented: $showDeleteAlert) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                viewModel.deleteGoal()
                onUpdate()
                dismiss()
            }
        } message: {
            Text("goals_delete_message".localized)
        }
    }
}

struct GoalHeroSection: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: goal.category.color),
                                Color(hex: goal.category.color).opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: goal.category.color).opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: goal.category.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Progress
            VStack(spacing: 8) {
                Text(String(format: "%.1f%%", goal.progressPercentage))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: goal.category.color))
                
                Text("goals_progress".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Status
            StatusBadge(status: goal.status)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: goal.category.color).opacity(0.1),
                            Color(hex: goal.category.color).opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
}

struct GoalRoadmapSection: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("goals_roadmap".localized)
                .font(.system(size: 18, weight: .semibold))
            
            VStack(spacing: 20) {
                RoadmapItem(
                    title: "Start",
                    amount: formatCurrency(0, currency: goal.currency),
                    date: formatDate(goal.createdAt),
                    isPassed: true,
                    isFirst: true
                )
                
                ForEach(goal.milestones.prefix(3), id: \.percentage) { milestone in
                    RoadmapItem(
                        title: "\(Int(milestone.percentage))% Milestone",
                        amount: formatCurrency(milestone.amount, currency: goal.currency),
                        date: milestone.isPassed ? "Completed" : "Upcoming",
                        isPassed: milestone.isPassed,
                        isFirst: false
                    )
                }
                
                RoadmapItem(
                    title: "Goal Achieved",
                    amount: formatCurrency(goal.targetAmount, currency: goal.currency),
                    date: formatDate(goal.deadline),
                    isPassed: goal.isCompleted,
                    isFirst: false,
                    isLast: true
                )
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

struct RoadmapItem: View {
    let title: String
    let amount: String
    let date: String
    let isPassed: Bool
    let isFirst: Bool
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(isPassed ? Color(hex: "4CAF50") : Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                ZStack {
                    Circle()
                        .fill(isPassed ? Color(hex: "4CAF50") : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    if isPassed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isPassed ? .primary : .secondary)
                
                Text(amount)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isPassed ? Color(hex: "4CAF50") : .secondary)
                
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct GoalProgressChart: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Projection")
                .font(.system(size: 18, weight: .semibold))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                    
                    // Current progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: goal.category.color),
                                    Color(hex: goal.category.color).opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(goal.progress))
                    
                    // Projected progress line
                    let projectedDate = goal.calculateProjectedCompletion()
                    let totalTime = goal.deadline.timeIntervalSince(goal.createdAt)
                    let elapsedTime = Date().timeIntervalSince(goal.createdAt)
                    let projectedTime = projectedDate.timeIntervalSince(goal.createdAt)
                    
                    if projectedTime <= totalTime * 1.2 {
                        Rectangle()
                            .fill(Color(hex: goal.category.color).opacity(0.3))
                            .frame(width: 2)
                            .offset(x: geometry.size.width * CGFloat(min(projectedTime / totalTime, 1.0)))
                    }
                }
                .frame(height: 40)
            }
            .frame(height: 40)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("goals_projected_completion".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(goal.calculateProjectedCompletion()))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("goals_required_monthly".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(goal.requiredMonthlyContribution, currency: goal.currency))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: goal.category.color))
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

struct ContributionHistorySection: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("goals_history".localized)
                .font(.system(size: 18, weight: .semibold))
            
            if viewModel.goal.contributions.isEmpty {
                Text("No contributions yet")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.goal.contributions.sorted(by: { $0.date > $1.date }).prefix(5)) { contribution in
                    ContributionRow(contribution: contribution, currency: viewModel.goal.currency)
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

struct ContributionRow: View {
    let contribution: Contribution
    let currency: Currency
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCurrency(contribution.amount, currency: currency))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(formatDate(contribution.date))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                if let note = contribution.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "4CAF50"))
        }
        .padding(.vertical, 8)
    }
}

struct AddContributionView: View {
    @ObservedObject var viewModel: GoalViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("goals_contribution_amount".localized)) {
                    HStack {
                        Text(viewModel.goal.currency.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "00B4A5"))
                        
                        TextField("0", value: $viewModel.newContributionAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }
                
                Section(header: Text("goals_contribution_date".localized)) {
                    DatePicker("Date", selection: $viewModel.newContributionDate, displayedComponents: .date)
                }
                
                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note...", text: $viewModel.newContributionNote)
                }
            }
            .navigationTitle("goals_add_contribution".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        viewModel.addContribution()
                        dismiss()
                    }
                    .disabled(viewModel.newContributionAmount <= 0)
                }
            }
        }
    }
}

struct CreateGoalView: View {
    @StateObject private var viewModel = GoalViewModel()
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("goals_name".localized)) {
                    TextField("e.g., Down Payment for House", text: $viewModel.goal.name)
                }
                
                Section(header: Text("goals_category".localized)) {
                    Picker("Category", selection: $viewModel.goal.category) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.localizedString)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Financial Details")) {
                    HStack {
                        Text("goals_target_amount".localized)
                        Spacer()
                        Text(viewModel.goal.currency.symbol)
                            .foregroundColor(Color(hex: "00B4A5"))
                        TextField("0", value: $viewModel.goal.targetAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    
                    HStack {
                        Text("goals_current_amount".localized)
                        Spacer()
                        Text(viewModel.goal.currency.symbol)
                            .foregroundColor(Color(hex: "00B4A5"))
                        TextField("0", value: $viewModel.goal.currentAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    
                    HStack {
                        Text("goals_monthly_contribution".localized)
                        Spacer()
                        Text(viewModel.goal.currency.symbol)
                            .foregroundColor(Color(hex: "00B4A5"))
                        TextField("0", value: $viewModel.goal.monthlyContribution, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                
                Section(header: Text("goals_deadline".localized)) {
                    DatePicker("Target Date", selection: $viewModel.goal.deadline, in: Date()..., displayedComponents: .date)
                }
                
                Section(header: Text("goals_notifications".localized)) {
                    Toggle("goals_notify_milestone".localized, isOn: $viewModel.goal.notifyOnMilestones)
                    Toggle("goals_notify_deadline".localized, isOn: $viewModel.goal.notifyBeforeDeadline)
                }
            }
            .navigationTitle("goals_create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        viewModel.saveGoal()
                        if viewModel.goal.notifyBeforeDeadline {
                            viewModel.scheduleDeadlineReminder()
                        }
                        onComplete()
                        dismiss()
                    }
                    .disabled(viewModel.goal.name.isEmpty || viewModel.goal.targetAmount <= 0)
                }
            }
        }
    }
}
