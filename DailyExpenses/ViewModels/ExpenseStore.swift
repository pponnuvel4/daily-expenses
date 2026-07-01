import Foundation
import Observation

@Observable
@MainActor
final class ExpenseStore {
    private(set) var expenses: [Expense] = []
    private(set) var favorites: [FavoriteExpense] = []
    private(set) var trips: [TripPlan] = []
    var selectedDate: Date
    var settings: AppSettings = AppSettings()

    private let calendar = Calendar.current
    private var lastActiveDay: Date?

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    init(selectedDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.selectedDate = calendar.startOfDay(for: selectedDate)
        load()
        _ = refreshForNewDayIfNeeded()
    }

    var expensesForSelectedDay: [Expense] {
        expenses(for: selectedDate, category: nil)
    }

    var selectedDayTotal: Double {
        dayTotal(for: selectedDate, category: nil)
    }

    var monthTotal: Double {
        monthTotal(forMonthContaining: selectedDate, category: nil)
    }

    func expenses(for day: Date, category: ExpenseCategory?) -> [Expense] {
        expenses
            .filter { expense in
                calendar.isDate(expense.date, inSameDayAs: day)
                    && matchesCategory(expense.category, filter: category)
            }
            .sorted { $0.date > $1.date }
    }

    func dayTotal(for day: Date, category: ExpenseCategory?) -> Double {
        expenses(for: day, category: category).reduce(0) { $0 + $1.amount }
    }

    func monthTotal(forMonthContaining date: Date, category: ExpenseCategory?) -> Double {
        expensesForMonth(containing: date, category: category).reduce(0) { $0 + $1.amount }
    }

    func favorites(for category: ExpenseCategory?) -> [FavoriteExpense] {
        guard let category else { return favorites }
        return favorites.filter { $0.category == category }
    }

    var selectedMonthTitle: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    var selectedDayTitle: String {
        if calendar.isDate(selectedDate, inSameDayAs: today) {
            return "Today"
        }
        if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    func addExpense(
        title: String,
        amount: Double,
        category: ExpenseCategory,
        note: String?,
        quantity: Double? = nil,
        unit: String? = nil,
        moneyFlow: MoneyFlow? = nil
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0 else { return }

        let expense = Expense(
            title: trimmedTitle,
            amount: amount,
            quantity: quantity,
            unit: unit,
            category: category,
            moneyFlow: moneyFlow,
            note: trimmedNote?.isEmpty == true ? nil : trimmedNote,
            date: selectedDate
        )
        expenses.insert(expense, at: 0)
        persist()
    }

    func moneyGivenTotal(for day: Date) -> Double {
        moneyTotal(for: day, flow: .given)
    }

    func moneyBorrowedTotal(for day: Date) -> Double {
        moneyTotal(for: day, flow: .borrowed)
    }

    func moneyNetTotal(for day: Date) -> Double {
        moneyBorrowedTotal(for: day) - moneyGivenTotal(for: day)
    }

    func moneyGivenTotal(forMonthContaining date: Date) -> Double {
        moneyTotal(forMonthContaining: date, flow: .given)
    }

    func moneyBorrowedTotal(forMonthContaining date: Date) -> Double {
        moneyTotal(forMonthContaining: date, flow: .borrowed)
    }

    func moneyNetTotal(forMonthContaining date: Date) -> Double {
        moneyBorrowedTotal(forMonthContaining: date) - moneyGivenTotal(forMonthContaining: date)
    }

    private func moneyTotal(for day: Date, flow: MoneyFlow, completed: Bool) -> Double {
        expenses(for: day, category: .money)
            .filter { $0.resolvedMoneyFlow == flow && $0.isMoneyCompleted == completed }
            .reduce(0) { $0 + $1.amount }
    }

    private func moneyTotal(forMonthContaining date: Date, flow: MoneyFlow, completed: Bool) -> Double {
        expensesForMonth(containing: date, category: .money)
            .filter { $0.resolvedMoneyFlow == flow && $0.isMoneyCompleted == completed }
            .reduce(0) { $0 + $1.amount }
    }

    private func moneyTotal(for day: Date, flow: MoneyFlow) -> Double {
        moneyTotal(for: day, flow: flow, completed: false)
    }

    private func moneyTotal(forMonthContaining date: Date, flow: MoneyFlow) -> Double {
        moneyTotal(forMonthContaining: date, flow: flow, completed: false)
    }

    func moneyGivenCompletedTotal(forMonthContaining date: Date) -> Double {
        moneyTotal(forMonthContaining: date, flow: .given, completed: true)
    }

    func moneyBorrowedCompletedTotal(forMonthContaining date: Date) -> Double {
        moneyTotal(forMonthContaining: date, flow: .borrowed, completed: true)
    }

    func toggleMoneyCompleted(for expense: Expense) {
        guard expense.category == .money,
              var updated = expenses.first(where: { $0.id == expense.id }) else { return }
        updated.moneyCompleted = !(updated.moneyCompleted ?? false)
        updateExpense(updated)
    }

    func duplicateExpense(_ expense: Expense) {
        addExpense(
            title: expense.title,
            amount: expense.amount,
            category: expense.category,
            note: expense.note,
            quantity: expense.quantity,
            unit: expense.unit,
            moneyFlow: expense.moneyFlow
        )
    }

    func outstandingMoneyEntries() -> [Expense] {
        expenses
            .filter { $0.category == .money && !$0.isMoneyCompleted }
            .sorted { $0.date > $1.date }
    }

    func personMoneySummaries() -> [PersonMoneySummary] {
        let grouped = Dictionary(grouping: outstandingMoneyEntries()) { $0.displayTitle.lowercased() }

        return grouped.map { key, entries in
            let name = entries.first?.displayTitle ?? key
            let given = entries.filter { $0.resolvedMoneyFlow == .given }.reduce(0) { $0 + $1.amount }
            let borrowed = entries.filter { $0.resolvedMoneyFlow == .borrowed }.reduce(0) { $0 + $1.amount }
            return PersonMoneySummary(
                id: key,
                name: name,
                givenOutstanding: given,
                borrowedOutstanding: borrowed,
                entries: entries
            )
        }
        .sorted { ($0.givenOutstanding + $0.borrowedOutstanding) > ($1.givenOutstanding + $1.borrowedOutstanding) }
    }

    func allOutstandingGivenTotal() -> Double {
        outstandingMoneyEntries()
            .filter { $0.resolvedMoneyFlow == .given }
            .reduce(0) { $0 + $1.amount }
    }

    func allOutstandingBorrowedTotal() -> Double {
        outstandingMoneyEntries()
            .filter { $0.resolvedMoneyFlow == .borrowed }
            .reduce(0) { $0 + $1.amount }
    }

    func allOutstandingNetTotal() -> Double {
        allOutstandingBorrowedTotal() - allOutstandingGivenTotal()
    }

    func weekTotal(forWeekContaining date: Date, category: ExpenseCategory?) -> Double {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return 0 }
        return expenses
            .filter { expense in
                expense.date >= interval.start
                    && expense.date < interval.end
                    && matchesCategory(expense.category, filter: category)
            }
            .reduce(0) { $0 + $1.amount }
    }

    func dailyTotalsForMonth(containing date: Date, category: ExpenseCategory?) -> [DailySpendingTotal] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }

        var amountsByDay: [Date: Double] = [:]
        for expense in expensesForMonth(containing: date, category: category) {
            let day = calendar.startOfDay(for: expense.date)
            amountsByDay[day, default: 0] += expense.amount
        }

        return amountsByDay
            .map { day, amount in
                DailySpendingTotal(
                    id: day,
                    label: day.formatted(.dateTime.day()),
                    amount: amount
                )
            }
            .sorted { $0.id < $1.id }
    }

    func budgetProgress(forMonthContaining date: Date) -> (spent: Double, budget: Double, remaining: Double)? {
        guard let budget = settings.monthlyBudget, budget > 0 else { return nil }
        let spent = monthTotal(forMonthContaining: date, category: nil)
        return (spent, budget, max(0, budget - spent))
    }

    func saveSettings() {
        persist()
    }

    func restorePersistedData() -> Int {
        let restored = ExpensePersistence.recoverFromAllSources()
        expenses = restored.expenses
        favorites = restored.favorites
        trips = restored.trips
        settings = restored.settings
        lastActiveDay = restored.lastActiveDay.map { calendar.startOfDay(for: $0) }
        persist()
        return restored.recordCount
    }

    var recoverableRecordCount: Int {
        ExpensePersistence.peekBestData().recordCount
    }

    var hasRecoverableData: Bool {
        recoverableRecordCount > expenses.count + favorites.count + trips.count
    }

    func updateExpense(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        persist()
    }

    func deleteExpenses(at offsets: IndexSet, from list: [Expense]) {
        let ids = offsets.map { list[$0].id }
        expenses.removeAll { ids.contains($0.id) }
        persist()
    }

    func shiftSelectedDate(byDays days: Int) {
        guard days != 0 else { return }
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        let normalized = calendar.startOfDay(for: newDate)
        guard normalized <= today else { return }
        selectedDate = normalized
    }

    func goToToday() {
        guard !calendar.isDate(selectedDate, inSameDayAs: today) else { return }
        selectedDate = today
    }

    var isViewingToday: Bool {
        calendar.isDate(selectedDate, inSameDayAs: today)
    }

    var canShiftForward: Bool {
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return false }
        return calendar.startOfDay(for: nextDate) <= today
    }

    @discardableResult
    func refreshForNewDayIfNeeded() -> Bool {
        let today = self.today

        if let lastActiveDay {
            let isNewDay = !calendar.isDate(lastActiveDay, inSameDayAs: today)
            if isNewDay {
                selectedDate = today
            }
            self.lastActiveDay = today
            persist()
            return isNewDay
        }

        self.lastActiveDay = today
        persist()
        return false
    }

    func addToFavorites(from expense: Expense) {
        let title = expense.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = title.isEmpty ? expense.category.title : title
        guard !favorites.contains(where: { $0.title.caseInsensitiveCompare(name) == .orderedSame }) else {
            return
        }

        favorites.insert(
            FavoriteExpense(
                title: name,
                amount: expense.amount,
                quantity: expense.quantity,
                unit: expense.unit,
                category: expense.category,
                moneyFlow: expense.moneyFlow
            ),
            at: 0
        )
        persist()
    }

    func addFavoriteToDay(_ favorite: FavoriteExpense) {
        addExpense(
            title: favorite.title,
            amount: favorite.amount,
            category: favorite.category,
            note: nil,
            quantity: favorite.quantity,
            unit: favorite.unit,
            moneyFlow: favorite.moneyFlow
        )
    }

    func removeFavorite(_ favorite: FavoriteExpense) {
        favorites.removeAll { $0.id == favorite.id }
        persist()
    }

    var tripsTotalAmount: Double {
        trips.reduce(0) { $0 + $1.totalAmount }
    }

    func addTrip(name: String, totalAmount: Double, peopleCount: Int, note: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard totalAmount > 0 else { return }

        let trip = TripPlan(
            name: trimmedName,
            totalAmount: totalAmount,
            peopleCount: peopleCount,
            note: trimmedNote?.isEmpty == true ? nil : trimmedNote
        )
        trips.insert(trip, at: 0)
        persist()
    }

    func updateTrip(_ trip: TripPlan) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index] = trip
        persist()
    }

    func deleteTrips(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        persist()
    }

    func categoryTotals(forMonthContaining date: Date, category: ExpenseCategory? = nil) -> [CategoryTotal] {
        let monthTotal = monthTotal(forMonthContaining: date, category: category)
        guard monthTotal > 0 else { return [] }

        let monthExpenses = expensesForMonth(containing: date, category: category)
        var amounts: [ExpenseCategory: Double] = [:]
        for expense in monthExpenses {
            amounts[expense.category, default: 0] += expense.amount
        }

        return amounts
            .map { category, amount in
                CategoryTotal(
                    id: category,
                    category: category,
                    amount: amount,
                    percentage: (amount / monthTotal) * 100
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    func expensesForReport(type: ExpenseReportType, on date: Date) -> [Expense] {
        if type.isMonthly {
            return expensesForMonth(containing: date, category: type.categoryFilter)
                .sorted { $0.date > $1.date }
        }
        return expenses(for: date, category: type.categoryFilter)
    }

    func totalForReport(type: ExpenseReportType, on date: Date) -> Double {
        if type.isMonthly {
            return monthTotal(forMonthContaining: date, category: type.categoryFilter)
        }
        return dayTotal(for: date, category: type.categoryFilter)
    }

    private func expensesForMonth(containing date: Date, category: ExpenseCategory? = nil) -> [Expense] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        return expenses.filter { expense in
            expense.date >= interval.start
                && expense.date < interval.end
                && matchesCategory(expense.category, filter: category)
        }
    }

    private func matchesCategory(_ category: ExpenseCategory, filter: ExpenseCategory?) -> Bool {
        guard let filter else { return true }
        return category == filter
    }

    private func load() {
        let appData = ExpensePersistence.load()
        expenses = appData.expenses
        favorites = appData.favorites
        trips = appData.trips
        settings = appData.settings
        lastActiveDay = appData.lastActiveDay.map { calendar.startOfDay(for: $0) }
    }

    private func persist() {
        try? ExpensePersistence.save(
            ExpenseAppData(
                expenses: expenses,
                favorites: favorites,
                trips: trips,
                lastActiveDay: lastActiveDay,
                settings: settings
            )
        )
    }
}
