import Foundation

struct ExpenseAppData: Codable {
    var expenses: [Expense] = []
    var favorites: [FavoriteExpense] = []
    var trips: [TripPlan] = []
    var lastActiveDay: Date?
    var settings: AppSettings = AppSettings()

    var recordCount: Int {
        expenses.count + favorites.count + trips.count + trips.reduce(0) { $0 + $1.entries.count }
    }
}

enum ExpensePersistence {
    private static let fileName = "daily-expenses-data.json"
    private static let backupFileName = "daily-expenses-data.backup.json"
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

    private static var backupFileURL: URL {
        storageDirectory.appendingPathComponent(backupFileName)
    }

    static func load() -> ExpenseAppData {
        let best = bestAvailableData(
            file: loadFromFile(),
            backup: loadFromBackupFile(),
            userDefaults: loadFromUserDefaults()
        )

        if best.recordCount > 0 {
            let fileCount = loadFromFile()?.recordCount ?? 0
            if best.recordCount > fileCount {
                try? save(best)
            }
        }

        return best
    }

    static func recoverFromAllSources() -> ExpenseAppData {
        let best = peekBestData()
        try? save(best)
        return best
    }

    static func peekBestData() -> ExpenseAppData {
        bestAvailableData(
            file: loadFromFile(),
            backup: loadFromBackupFile(),
            userDefaults: loadFromUserDefaults()
        )
    }

    static func save(_ appData: ExpenseAppData) throws {
        if let existing = loadFromFile(),
           existing.recordCount > appData.recordCount,
           appData.recordCount == 0 {
            return
        }

        backupCurrentFileIfNeeded()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(appData)
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication] as Data.WritingOptions
        )
    }

    private static func backupCurrentFileIfNeeded() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try? FileManager.default.removeItem(at: backupFileURL)
        try? FileManager.default.copyItem(at: fileURL, to: backupFileURL)
    }

    private static func loadFromFile() -> ExpenseAppData? {
        decodeAppData(at: fileURL)
    }

    private static func loadFromBackupFile() -> ExpenseAppData? {
        decodeAppData(at: backupFileURL)
    }

    private static func loadFromUserDefaults() -> ExpenseAppData? {
        if let data = UserDefaults.standard.data(forKey: appDataKey),
           let decoded = decodeAppData(from: data) {
            return decoded
        }

        if let legacyData = UserDefaults.standard.data(forKey: legacyExpensesKey),
           let expenses = decodeExpenses(from: legacyData) {
            return ExpenseAppData(expenses: expenses)
        }

        return nil
    }

    private static func decodeAppData(at url: URL) -> ExpenseAppData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decodeAppData(from: data)
    }

    private static func decodeAppData(from data: Data) -> ExpenseAppData? {
        let decoder = makeDecoder()
        return try? decoder.decode(ExpenseAppData.self, from: data)
    }

    private static func decodeExpenses(from data: Data) -> [Expense]? {
        let decoder = makeDecoder()
        return try? decoder.decode([Expense].self, from: data)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let isoString = try? container.decode(String.self),
               let date = ISO8601DateFormatter().date(from: isoString) {
                return date
            }
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: timestamp)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format")
        }
        return decoder
    }

    private static func bestAvailableData(
        file: ExpenseAppData?,
        backup: ExpenseAppData?,
        userDefaults: ExpenseAppData?
    ) -> ExpenseAppData {
        let candidates = [file, backup, userDefaults].compactMap { $0 }
        guard !candidates.isEmpty else { return ExpenseAppData() }
        return candidates.max(by: { $0.recordCount < $1.recordCount }) ?? ExpenseAppData()
    }
}
