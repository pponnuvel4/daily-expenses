import Foundation

struct ExpenseAppData: Codable {
    var expenses: [Expense] = []
    var favorites: [FavoriteExpense] = []
    var lastActiveDay: Date?
}

enum ExpensePersistence {
    private static let appDataKey = "daily_expenses_app_data_v1"
    private static let legacyExpensesKey = "daily_expenses_legacy_v0"

    static func load() -> ExpenseAppData {
        if let data = UserDefaults.standard.data(forKey: appDataKey),
           let decoded = try? JSONDecoder().decode(ExpenseAppData.self, from: data) {
            return decoded
        }

        if let legacyData = UserDefaults.standard.data(forKey: legacyExpensesKey),
           let expenses = try? JSONDecoder().decode([Expense].self, from: legacyData) {
            return ExpenseAppData(expenses: expenses)
        }

        return ExpenseAppData()
    }

    static func save(_ appData: ExpenseAppData) {
        guard let data = try? JSONEncoder().encode(appData) else { return }
        UserDefaults.standard.set(data, forKey: appDataKey)
    }
}
