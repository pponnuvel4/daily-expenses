import Foundation

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var favorites: [FavoriteExpense] = []
    @Published var selectedDate: Date

    private let calendar = Calendar.current
    private var lastActiveDay: Date?

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
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        }
        if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    func addExpense(title: String, amount: Double, category: ExpenseCategory, note: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0 else { return }

        let expense = Expense(
            title: trimmedTitle,
            amount: amount,
            category: category,
            note: trimmedNote?.isEmpty == true ? nil : trimmedNote,
            date: selectedDate
        )
        expenses.insert(expense, at: 0)
        persist()
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
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = calendar.startOfDay(for: newDate)
    }

    func goToToday() {
        selectedDate = calendar.startOfDay(for: Date())
    }

    var isViewingToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    @discardableResult
    func refreshForNewDayIfNeeded() -> Bool {
        let today = calendar.startOfDay(for: Date())

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
        selectedDate = today
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
            FavoriteExpense(title: name, amount: expense.amount, category: expense.category),
            at: 0
        )
        persist()
    }

    func addFavoriteToDay(_ favorite: FavoriteExpense) {
        addExpense(
            title: favorite.title,
            amount: favorite.amount,
            category: favorite.category,
            note: nil
        )
    }

    func removeFavorite(_ favorite: FavoriteExpense) {
        favorites.removeAll { $0.id == favorite.id }
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
        lastActiveDay = appData.lastActiveDay.map { calendar.startOfDay(for: $0) }
    }

    private func persist() {
        ExpensePersistence.save(
            ExpenseAppData(
                expenses: expenses,
                favorites: favorites,
                lastActiveDay: lastActiveDay
            )
        )
    }
}
