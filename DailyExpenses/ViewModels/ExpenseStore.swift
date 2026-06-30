import Foundation

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published var selectedDate: Date

    private let calendar = Calendar.current

    init(selectedDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.selectedDate = calendar.startOfDay(for: selectedDate)
        load()
    }

    var expensesForSelectedDay: [Expense] {
        expenses
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    var selectedDayTotal: Double {
        expensesForSelectedDay.reduce(0) { $0 + $1.amount }
    }

    var monthTotal: Double {
        guard let interval = calendar.dateInterval(of: .month, for: selectedDate) else { return 0 }
        return expenses
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .reduce(0) { $0 + $1.amount }
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

    func deleteExpenses(at offsets: IndexSet, from list: [Expense]) {
        let ids = offsets.map { list[$0].id }
        expenses.removeAll { ids.contains($0.id) }
        persist()
    }

    func shiftSelectedDate(byDays days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = calendar.startOfDay(for: newDate)
    }

    private func load() {
        expenses = ExpensePersistence.load().expenses
    }

    private func persist() {
        ExpensePersistence.save(ExpenseAppData(expenses: expenses))
    }
}
