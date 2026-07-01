import Foundation

struct ExpenseAppData: Codable {
    var expenses: [Expense] = []
    var favorites: [FavoriteExpense] = []
    var lastActiveDay: Date?
    var settings: AppSettings = AppSettings()
}

enum ExpensePersistence {
    private static let fileName = "daily-expenses-data.json"
    private static let appDataKey = "daily_expenses_app_data_v1"
    private static let legacyExpensesKey = "daily_expenses_legacy_v0"

    private static var storageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("DailyExpenses", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static var fileURL: URL {
        storageDirectory.appendingPathComponent(fileName)
    }

    static func load() -> ExpenseAppData {
        if let fileData = loadFromFile() {
            return fileData
        }

        if let userDefaultsData = loadFromUserDefaults() {
            try? save(userDefaultsData)
            return userDefaultsData
        }

        return ExpenseAppData()
    }

    static func save(_ appData: ExpenseAppData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(appData)
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication] as Data.WritingOptions
        )
    }

    private static func loadFromFile() -> ExpenseAppData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(ExpenseAppData.self, from: data)
    }

    private static func loadFromUserDefaults() -> ExpenseAppData? {
        if let data = UserDefaults.standard.data(forKey: appDataKey),
           let decoded = try? JSONDecoder().decode(ExpenseAppData.self, from: data) {
            return decoded
        }

        if let legacyData = UserDefaults.standard.data(forKey: legacyExpensesKey),
           let expenses = try? JSONDecoder().decode([Expense].self, from: legacyData) {
            return ExpenseAppData(expenses: expenses)
        }

        return nil
    }
}
