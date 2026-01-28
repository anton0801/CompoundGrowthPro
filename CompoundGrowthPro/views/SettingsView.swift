import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showExportSuccess = false
    @State private var showImportPicker = false
    @State private var showClearAlert = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("settings_appearance".localized)) {
                    Picker("settings_theme".localized, selection: $viewModel.settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.localizedString).tag(theme)
                        }
                    }
                    .onChange(of: viewModel.settings.theme) { _ in
                        viewModel.saveSettings()
                    }
                }
                
                // Default Settings
                Section(header: Text("settings_defaults".localized)) {
                    Picker("calc_currency".localized, selection: $viewModel.settings.defaultCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.rawValue)
                            }
                            .tag(currency)
                        }
                    }
                    .onChange(of: viewModel.settings.defaultCurrency) { _ in
                        viewModel.saveSettings()
                    }
                }
                
                // Notifications
                Section(header: Text("settings_notifications".localized)) {
                    Toggle("settings_reminders".localized, isOn: $viewModel.settings.notificationsEnabled)
                        .onChange(of: viewModel.settings.notificationsEnabled) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                // Security
                Section(header: Text("settings_security".localized)) {
                    Toggle("settings_biometric".localized, isOn: $viewModel.settings.biometricAuthEnabled)
                        .onChange(of: viewModel.settings.biometricAuthEnabled) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                // Data Management
                Section(header: Text("settings_data".localized)) {
                    Button(action: {
                        if let url = viewModel.exportData() {
                            shareFile(url: url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "00B4A5"))
                            Text("settings_export".localized)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        showImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(Color(hex: "FFB300"))
                            Text("settings_import".localized)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        showClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("settings_clear".localized)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Currency Rates
                Section(header: Text("settings_currency_rates".localized)) {
                    NavigationLink(destination: CurrencyRatesView(settings: $viewModel.settings)) {
                        Text("Manage Rates")
                    }
                }
                
                // About
                Section(header: Text("settings_about".localized)) {
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color(hex: "00B4A5"))
                            Text("about_title".localized)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    NavigationLink(destination: FAQView()) {
                        Text("settings_faq".localized)
                    }
                    
                    NavigationLink(destination: FormulasView()) {
                        Text("settings_formulas".localized)
                    }
                    
                    HStack {
                        Text("settings_version".localized)
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings_title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("settings_clear_confirm".localized, isPresented: $showClearAlert) {
            Button("cancel".localized, role: .cancel) {}
            Button("settings_clear".localized, role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("settings_clear_message".localized)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker { url in
                _ = viewModel.importData(from: url)
            }
        }
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct CurrencyRatesView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Курсы относительно USD")) {
                ForEach(Array(settings.currencyRates.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        TextField("0.0", value: Binding(
                            get: { settings.currencyRates[key] ?? 1.0 },
                            set: { settings.currencyRates[key] = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                }
            }
            
            Section {
                Button("Обновить курсы") {
                    // Manual update functionality
                    dismiss()
                }
            }
        }
        .navigationTitle("Курсы валют")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon
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
                            .frame(width: 120, height: 120)
                        
                        CompoundGraphIcon()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("app_name".localized)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("settings_version".localized + " 1.1.0")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("about_title".localized)
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal)
                        
                        Text("about_description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "about_feature_1".localized, description: "about_feature_1_desc".localized)
                        FeatureRow(icon: "chart.bar.fill", title: "about_feature_2".localized, description: "about_feature_2_desc".localized)
                        FeatureRow(icon: "lock.shield.fill", title: "about_feature_3".localized, description: "about_feature_3_desc".localized)
                        FeatureRow(icon: "gearshape.fill", title: "about_feature_4".localized, description: "about_feature_4_desc".localized)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                    
                    Text("about_copyright".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "00B4A5"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct FAQView: View {
    let faqs = [
        FAQ(question: "Что такое сложный процент?", answer: "Сложный процент — это проценты, начисляемые на первоначальную сумму и на проценты, накопленные за предыдущие периоды. Это создает эффект 'процентов на проценты', приводя к экспоненциальному росту."),
        FAQ(question: "Как часто начисляются проценты?", answer: "Частота начислений влияет на итоговую сумму. Чем чаще начисляются проценты (ежедневно, ежемесячно, ежегодно), тем больше будет итоговая сумма при одинаковой годовой ставке."),
        FAQ(question: "Что такое реальная прибыль?", answer: "Реальная прибыль учитывает влияние инфляции на покупательную способность ваших денег. Это показывает, сколько вы реально заработали с учетом роста цен."),
        FAQ(question: "Как сохранить расчет?", answer: "После выполнения расчета нажмите кнопку 'Сохранить расчет', введите название и сохраните. Все расчеты хранятся локально на вашем устройстве."),
        FAQ(question: "Можно ли экспортировать данные?", answer: "Да! В настройках выберите 'Экспортировать данные' для создания резервной копии всех расчетов и профилей в формате JSON.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(faqs) { faq in
                    FAQCard(faq: faq)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Часто задаваемые вопросы")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQCard: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "00B4A5"))
                }
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct FormulasView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FormulaSection(
                    title: "Сложный процент",
                    formula: "A = P(1 + r/n)^(nt)",
                    description: "Основная формула для расчета сложного процента с периодическим начислением.",
                    variables: [
                        ("A", "Итоговая сумма"),
                        ("P", "Начальная сумма (Principal)"),
                        ("r", "Годовая процентная ставка (в десятичной форме)"),
                        ("n", "Количество начислений в год"),
                        ("t", "Время в годах")
                    ]
                )
                
                FormulaSection(
                    title: "С регулярными вкладами",
                    formula: "FV = P(1 + r/n)^(nt) + PMT × [((1 + r/n)^(nt) - 1) / (r/n)]",
                    description: "Расчет с учетом регулярных дополнительных взносов.",
                    variables: [
                        ("FV", "Будущая стоимость"),
                        ("PMT", "Регулярный платеж"),
                        ("P, r, n, t", "См. основную формулу")
                    ]
                )
                
                FormulaSection(
                    title: "Реальная прибыль",
                    formula: "Real Return = Nominal Return / (1 + Inflation Rate)^t",
                    description: "Корректировка прибыли с учетом инфляции.",
                    variables: [
                        ("t", "Время в годах"),
                        ("Inflation Rate", "Годовая ставка инфляции")
                    ]
                )
            }
            .padding()
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Формулы")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FormulaSection: View {
    let title: String
    let formula: String
    let description: String
    let variables: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            
            Text(formula)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "00B4A5"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "00B4A5").opacity(0.1))
                )
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Переменные:")
                    .font(.system(size: 14, weight: .semibold))
                
                ForEach(variables, id: \.0) { variable in
                    HStack(spacing: 8) {
                        Text(variable.0)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "FFB300"))
                            .frame(width: 30, alignment: .leading)
                        
                        Text("–")
                            .foregroundColor(.secondary)
                        
                        Text(variable.1)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Фильтры")) {
                    Text("Функция в разработке")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: (URL) -> Void
        
        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onSelect(url)
        }
    }
}
