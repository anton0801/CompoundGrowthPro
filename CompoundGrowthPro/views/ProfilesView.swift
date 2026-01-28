import SwiftUI

struct ProfilesView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showCreateProfile = false
    @State private var selectedProfile: UserProfile?
    @State private var showDeleteAlert = false
    @State private var profileToDelete: UserProfile?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.profiles.isEmpty {
//                    EmptyStateView(
//                        icon: "person.2.fill",
//                        title: "profiles_empty".localized,
//                        description: "profiles_empty_desc".localized
//                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                ProfileCard(profile: profile)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        viewModel.selectProfile(profile)
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            selectedProfile = profile
                                        }) {
                                            Label("edit".localized, systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            profileToDelete = profile
                                            showDeleteAlert = true
                                        }) {
                                            Label("delete".localized, systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("profiles_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateProfile = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "00B4A5"))
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateProfile) {
            ProfileEditView(viewModel: ProfileViewModel()) {
                viewModel.loadData()
            }
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileEditView(viewModel: ProfileViewModel(profile: profile)) {
                viewModel.loadData()
            }
        }
        .alert("profiles_delete_confirm".localized, isPresented: $showDeleteAlert) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                if let profile = profileToDelete {
                    viewModel.deleteProfile(profile)
                }
            }
        } message: {
            Text("profiles_delete_message".localized)
        }
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "00B4A5"),
                                    Color(hex: "00897B")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(profile.name.prefix(2).uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formatDate(profile.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("profiles_calculations".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("\(profile.calculationIDs.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "00B4A5"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("calc_currency".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(profile.defaultCurrency.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FFB300"))
                }
                
                if profile.defaultInflationRate > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("calc_inflation".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", profile.defaultInflationRate))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FF9800"))
                    }
                }
                
                Spacer()
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

struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("profiles_name".localized, text: $viewModel.profile.name)
                }
                
                Section(header: Text("settings_defaults".localized)) {
                    Picker("calc_currency".localized, selection: $viewModel.profile.defaultCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    
                    HStack {
                        Text("calc_inflation".localized)
                        Spacer()
                        TextField("0", value: $viewModel.profile.defaultInflationRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("profiles_created".localized + ": \(formatDate(viewModel.profile.createdAt))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(viewModel.isNew ? "profiles_new".localized : "profiles_edit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        viewModel.save()
                        onSave()
                        dismiss()
                    }
                    .disabled(viewModel.profile.name.isEmpty)
                }
            }
        }
    }
}
