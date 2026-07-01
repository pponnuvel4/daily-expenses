import SwiftUI

struct ContentView: View {
    let scope: ExpenseTrackerScope
    @ObservedObject var store: ExpenseStore
    @State private var showDatePicker = false
    @State private var showMonthSummary = false
    @State private var showExportReport = false
    @State private var showAddExpense = false
    @State private var expenseToEdit: Expense?

    init(store: ExpenseStore, scope: ExpenseTrackerScope = .daily) {
        self.store = store
        self.scope = scope
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
            List {
                Section {
                    dateNavigationBar
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                Section {
                    summaryBanner
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(
                    scope == .farming ? Color.brown.opacity(0.08) : Color.accentColor.opacity(0.08)
                )

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
                                onAddFavorite: { store.addToFavorites(from: expense) }
                            )
                        }
                        .onDelete { offsets in
                            store.deleteExpenses(at: offsets, from: scopedExpenses)
                        }
                    }
                } header: {
                    Text("Expenses")
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
                AddExpenseView(scope: scope, store: store)
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
                Text(store.selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !store.isViewingToday {
                    Button("Jump to today") {
                        store.goToToday()
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
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No expenses", systemImage: scope.tabIcon)
        } description: {
            Text("\(scope.emptyStateMessage) \(store.selectedDayTitle.lowercased()).")
        } actions: {
            Button("Add expense") {
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
}

#Preview {
    ContentView(store: ExpenseStore(), scope: .daily)
}
