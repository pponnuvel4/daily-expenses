import Foundation

struct ExpenseAppData: Codable {
    var expenses: [Expense] = []
}

enum ExpensePersistence {
    private static let appDataKey = "daily_expenses_app_data_v1"

    static func load() -> ExpenseAppData {
        guard
            let data = UserDefaults.standard.data(forKey: appDataKey),
            let decoded = try? JSONDecoder().decode(ExpenseAppData.self, from: data)
        else {
            return ExpenseAppData()
        }
        return decoded
    }

    static func save(_ appData: ExpenseAppData) {
        guard let data = try? JSONEncoder().encode(appData) else { return }
        UserDefaults.standard.set(data, forKey: appDataKey)
    }
}
