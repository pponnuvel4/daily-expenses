import SwiftUI

struct ContentView: View {
    let scope: ExpenseTrackerScope
    @Environment(ExpenseStore.self) private var store
    @State private var showDatePicker = false
    @State private var showMonthSummary = false
    @State private var showExportReport = false
    @State private var showAddExpense = false
    @State private var expenseToEdit: Expense?

    init(scope: ExpenseTrackerScope = .daily) {
        self.scope = scope
    }

    private var scopedExpenses: [Expense] {
        let list = store.expenses(for: store.selectedDate, category: scope.categoryFilter)
        guard scope.isMoneyScope else { return list }
        return list.sorted { lhs, rhs in
            if lhs.isMoneyCompleted != rhs.isMoneyCompleted {
                return !lhs.isMoneyCompleted && rhs.isMoneyCompleted
            }
            return lhs.date > rhs.date
        }
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
        case .groceries: .selectedDayGroceries
        case .farming: .selectedDayFarming
        case .money: .selectedDayMoney
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dateNavigationBar
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                Section {
                    if scope.isMoneyScope {
                        moneySummaryBanner
                    } else {
                        summaryBanner
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(scope.listBannerColor)

                if !scopedFavorites.isEmpty {
                    Section {
                        FavoritesBarView(favorites: scopedFavorites) { favorite in
                            store.addFavoriteToDay(favorite)
                        } onRemove: { favorite in
                            store.removeFavorite(favorite)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section {
                    if scopedExpenses.isEmpty {
                        emptyState
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(scopedExpenses) { expense in
                            ExpenseRowView(
                                expense: expense,
                                onTap: { expenseToEdit = expense },
                                onAddFavorite: { store.addToFavorites(from: expense) },
                                onToggleCompleted: scope.isMoneyScope
                                    ? { store.toggleMoneyCompleted(for: expense) }
                                    : nil
                            )
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if scope.isMoneyScope, let flow = expense.resolvedMoneyFlow {
                                    Button {
                                        store.toggleMoneyCompleted(for: expense)
                                    } label: {
                                        Label(
                                            flow.markCompletedLabel(isCompleted: expense.isMoneyCompleted),
                                            systemImage: expense.isMoneyCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(expense.isMoneyCompleted ? .orange : .green)
                                }
                            }
                        }
                        .onDelete { offsets in
                            store.deleteExpenses(at: offsets, from: scopedExpenses)
                        }
                    }
                } header: {
                    Text(scope.isMoneyScope ? "Entries" : "Expenses")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(scope.title)
            .toolbar {
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
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add expense")

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
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(scope: scope)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showMonthSummary) {
                MonthSummaryView(scope: scope)
            }
            .sheet(isPresented: $showExportReport) {
                ExportReportView(defaultReportType: defaultReportType)
            }
            .sheet(item: $expenseToEdit) { expense in
                EditExpenseView(
                    expense: expense,
                    lockedCategory: scope.categoryFilter,
                    showsQuantityFields: scope.showsQuantityFields,
                    isMoneyScope: scope.isMoneyScope
                ) { updated in
                    store.updateExpense(updated)
                }
            }
        }
    }

    private var dateNavigationBar: some View {
        HStack {
            Button {
                store.shiftSelectedDate(byDays: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous day")

            Spacer()

            VStack(spacing: 2) {
                Text(store.selectedDayTitle)
                    .font(.headline)
                if !store.isViewingToday {
                    Text(store.selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Jump to today") {
                        store.goToToday()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                store.shiftSelectedDate(byDays: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next day")
            .disabled(!store.canShiftForward)
        }
    }

    private var moneySummaryBanner: some View {
        VStack(spacing: 12) {
            Text("Outstanding")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Given")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: store.moneyGivenTotal(for: store.selectedDate)))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.red)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Borrowed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: store.moneyBorrowedTotal(for: store.selectedDate)))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Net")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: store.moneyNetTotal(for: store.selectedDate)))
                        .font(.title3.weight(.bold))
                }
            }

            Divider()

            HStack {
                Text(store.selectedMonthTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Net \(CurrencyFormatter.string(from: store.moneyNetTotal(forMonthContaining: store.selectedDate)))")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
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
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(scope.isMoneyScope ? "No entries" : "No expenses", systemImage: scope.tabIcon)
        } description: {
            Text("\(scope.emptyStateMessage) \(store.selectedDayTitle.lowercased()).")
        } actions: {
            Button(scope.isMoneyScope ? "Record money" : "Add expense") {
                showAddExpense = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Select date",
                selection: selectedDateBinding,
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

    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { store.selectedDate },
            set: { store.selectedDate = Calendar.current.startOfDay(for: $0) }
        )
    }
}

#Preview {
    ContentView(scope: .daily)
        .environment(ExpenseStore())
}
