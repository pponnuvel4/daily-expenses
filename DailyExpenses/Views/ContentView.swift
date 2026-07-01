import SwiftUI

struct ContentView: View {
    private enum AddField: Hashable {
        case title
        case amount
        case note
    }

    @ObservedObject var store: ExpenseStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var newTitle = ""
    @State private var newAmountText = ""
    @State private var newCategory: ExpenseCategory = .food
    @State private var newNote = ""
    @State private var showDatePicker = false
    @State private var showMonthSummary = false
    @State private var expenseToEdit: Expense?
    @FocusState private var focusedField: AddField?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                addExpenseBar
                summaryBanner

                if !store.favorites.isEmpty {
                    FavoritesBarView(store: store)
                }

                if store.expensesForSelectedDay.isEmpty {
                    emptyState
                } else {
                    expenseList
                }
            }
            .navigationTitle("Daily Expenses")
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

                ToolbarItem(placement: .topBarTrailing) {
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
                MonthSummaryView(store: store)
            }
            .sheet(item: $expenseToEdit) { expense in
                EditExpenseView(expense: expense) { updated in
                    store.updateExpense(updated)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                if store.refreshForNewDayIfNeeded() {
                    clearAddForm()
                }
            }
        }
    }

    private var addExpenseBar: some View {
        VStack(spacing: 10) {
            dateNavigationBar

            TextField("What did you spend on?", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .amount }
                .onTapGesture { focusedField = .title }

            TextField("Amount", text: $newAmountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .amount)

            Picker("Category", selection: $newCategory) {
                ForEach(ExpenseCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon).tag(category)
                }
            }
            .pickerStyle(.menu)

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
                Text(CurrencyFormatter.string(from: store.selectedDayTotal))
                    .font(.title3.weight(.bold))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(store.selectedMonthTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.string(from: store.monthTotal))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.08))
    }

    private var expenseList: some View {
        List {
            Section {
                ForEach(store.expensesForSelectedDay) { expense in
                    ExpenseRowView(
                        expense: expense,
                        onTap: { expenseToEdit = expense },
                        onAddFavorite: { store.addToFavorites(from: expense) }
                    )
                }
                .onDelete { offsets in
                    store.deleteExpenses(at: offsets, from: store.expensesForSelectedDay)
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
            Label("No expenses", systemImage: "indianrupeesign.circle")
        } description: {
            Text("Add what you spent on \(store.selectedDayTitle.lowercased()).")
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
            category: newCategory,
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
        newCategory = .food
        focusedField = nil
    }
}

#Preview {
    ContentView(store: ExpenseStore())
}
