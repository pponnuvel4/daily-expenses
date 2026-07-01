import SwiftUI

struct ContentView: View {
    private enum AddField: Hashable {
        case title
        case amount
        case note
    }

    let scope: ExpenseTrackerScope
    @ObservedObject var store: ExpenseStore
    @State private var newTitle = ""
    @State private var newAmountText = ""
    @State private var newCategory: ExpenseCategory
    @State private var newNote = ""
    @State private var showDatePicker = false
    @State private var showMonthSummary = false
    @State private var showExportReport = false
    @State private var expenseToEdit: Expense?
    @FocusState private var focusedField: AddField?

    init(store: ExpenseStore, scope: ExpenseTrackerScope = .daily) {
        self.store = store
        self.scope = scope
        _newCategory = State(initialValue: scope.defaultCategory)
    }

    private var scopedExpenses: [Expense] {
        store.expenses(for: store.selectedDate, category: scope.categoryFilter)
    }

    private var scopedDayTotal: Double {
        store.dayTotal(for: store.selectedDate, category: scope.categoryFilter)
    }

    private var scopedMonthTotal: Double {
        store.monthTotal(forMonthContaining: store.selectedDate, category: scope.categoryFilter)
    }

    private var scopedFavorites: [FavoriteExpense] {
        store.favorites(for: scope.categoryFilter)
    }

    private var defaultReportType: ExpenseReportType {
        switch scope {
        case .daily: .selectedDay
        case .farming: .selectedDayFarming
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                addExpenseBar
                summaryBanner

                if !scopedFavorites.isEmpty {
                    FavoritesBarView(favorites: scopedFavorites) { favorite in
                        store.addFavoriteToDay(favorite)
                    } onRemove: { favorite in
                        store.removeFavorite(favorite)
                    }
                }

                if scopedExpenses.isEmpty {
                    emptyState
                } else {
                    expenseList
                }
            }
            .navigationTitle(scope.title)
            .navigationSubtitle(appVersionLabel)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMonthSummary = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .accessibilityLabel("Month summary")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showExportReport = true
                    } label: {
                        Image(systemName: "doc.richtext")
                    }
                    .accessibilityLabel("Export PDF report")

                    Button {
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("Pick date")
                }
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showMonthSummary) {
                MonthSummaryView(store: store, scope: scope)
            }
            .sheet(isPresented: $showExportReport) {
                ExportReportView(store: store, defaultReportType: defaultReportType)
            }
            .sheet(item: $expenseToEdit) { expense in
                EditExpenseView(
                    expense: expense,
                    lockedCategory: scope.categoryFilter
                ) { updated in
                    store.updateExpense(updated)
                }
            }
        }
    }

    private var addExpenseBar: some View {
        VStack(spacing: 10) {
            dateNavigationBar

            TextField(scope.addPrompt, text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .amount }
                .onTapGesture { focusedField = .title }

            TextField("Amount", text: $newAmountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .amount)

            if scope.showsCategoryPicker {
                Picker("Category", selection: $newCategory) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.title, systemImage: category.icon).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            TextField("Note (optional)", text: $newNote)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .note)
                .submitLabel(.done)
                .onSubmit { addExpense(refocusKeyboard: false) }

            Button("Add") {
                addExpense(refocusKeyboard: true)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(parsedAmount == nil)
        }
        .padding()
        .background(.bar)
    }

    private var dateNavigationBar: some View {
        HStack {
            Button {
                store.shiftSelectedDate(byDays: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous day")

            Spacer()

            VStack(spacing: 2) {
                Text(store.selectedDayTitle)
                    .font(.headline)
                Text(store.selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !store.isViewingToday {
                    Button("Jump to today") {
                        store.goToToday()
                        clearAddForm()
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            Spacer()

            Button {
                store.shiftSelectedDate(byDays: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Next day")
            .disabled(Calendar.current.isDateInToday(store.selectedDate))
        }
    }

    private var summaryBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.string(from: scopedDayTotal))
                    .font(.title3.weight(.bold))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(store.selectedMonthTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.string(from: scopedMonthTotal))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(scope == .farming ? Color.brown.opacity(0.08) : Color.accentColor.opacity(0.08))
    }

    private var expenseList: some View {
        List {
            Section {
                ForEach(scopedExpenses) { expense in
                    ExpenseRowView(
                        expense: expense,
                        onTap: { expenseToEdit = expense },
                        onAddFavorite: { store.addToFavorites(from: expense) }
                    )
                }
                .onDelete { offsets in
                    store.deleteExpenses(at: offsets, from: scopedExpenses)
                }
            } header: {
                Text("Expenses")
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No expenses", systemImage: scope.tabIcon)
        } description: {
            Text("\(scope.emptyStateMessage) \(store.selectedDayTitle.lowercased()).")
        }
        .frame(maxHeight: .infinity)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Select date",
                selection: $store.selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Pick Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.selectedDate = Calendar.current.startOfDay(for: store.selectedDate)
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }

    private var parsedAmount: Double? {
        let normalized = newAmountText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private func addExpense(refocusKeyboard: Bool) {
        guard let amount = parsedAmount else { return }

        store.addExpense(
            title: newTitle,
            amount: amount,
            category: scope.showsCategoryPicker ? newCategory : scope.defaultCategory,
            note: newNote
        )
        clearAddForm()

        if refocusKeyboard {
            Task { @MainActor in
                focusedField = .title
            }
        } else {
            focusedField = nil
        }
    }

    private func clearAddForm() {
        newTitle = ""
        newAmountText = ""
        newNote = ""
        newCategory = scope.defaultCategory
        focusedField = nil
    }
}

#Preview {
    ContentView(store: ExpenseStore(), scope: .daily)
}
