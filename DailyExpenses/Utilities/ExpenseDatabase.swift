import Foundation
import SwiftData

@MainActor
final class ExpenseDatabase {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadSnapshot() -> ExpenseAppData {
        let expenses = (try? context.fetch(FetchDescriptor<StoredExpense>()))?.map { $0.toExpense() } ?? []
        let favorites = (try? context.fetch(FetchDescriptor<StoredFavorite>()))?.map { $0.toFavorite() } ?? []
        let trips = (try? context.fetch(FetchDescriptor<StoredTrip>()))?.map { $0.toTrip() } ?? []
        let appState = fetchAppState()

        return ExpenseAppData(
            expenses: expenses.sorted { $0.date > $1.date },
            favorites: favorites,
            trips: trips.sorted { $0.date > $1.date },
            lastActiveDay: appState?.lastActiveDay,
            settings: appState?.toSettings() ?? AppSettings()
        )
    }

    func save(_ data: ExpenseAppData) throws {
        try syncExpenses(data.expenses)
        try syncFavorites(data.favorites)
        try syncTrips(data.trips)
        try syncAppState(settings: data.settings, lastActiveDay: data.lastActiveDay)
        try context.save()
        try? ExpensePersistence.save(data)
    }

    func importAll(_ data: ExpenseAppData) throws {
        try save(data)
    }

    func migrateLegacyDataIfNeeded() throws {
        let current = loadSnapshot()
        let legacy = ExpensePersistence.peekBestData()

        guard legacy.recordCount > current.recordCount else { return }
        try importAll(legacy)
    }

    func recoverFromLegacySources() throws -> ExpenseAppData {
        let legacy = ExpensePersistence.recoverFromAllSources()
        try importAll(legacy)
        return loadSnapshot()
    }

    private func syncExpenses(_ expenses: [Expense]) throws {
        let existing = try context.fetch(FetchDescriptor<StoredExpense>())
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let newIDs = Set(expenses.map(\.id))

        for expense in expenses {
            if let stored = existingByID[expense.id] {
                stored.update(from: expense)
            } else {
                context.insert(StoredExpense(from: expense))
            }
        }

        for stored in existing where !newIDs.contains(stored.id) {
            context.delete(stored)
        }
    }

    private func syncFavorites(_ favorites: [FavoriteExpense]) throws {
        let existing = try context.fetch(FetchDescriptor<StoredFavorite>())
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let newIDs = Set(favorites.map(\.id))

        for favorite in favorites {
            if let stored = existingByID[favorite.id] {
                stored.update(from: favorite)
            } else {
                context.insert(StoredFavorite(from: favorite))
            }
        }

        for stored in existing where !newIDs.contains(stored.id) {
            context.delete(stored)
        }
    }

    private func syncTrips(_ trips: [TripPlan]) throws {
        let existing = try context.fetch(FetchDescriptor<StoredTrip>())
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let newIDs = Set(trips.map(\.id))

        for trip in trips {
            if let stored = existingByID[trip.id] {
                stored.update(from: trip)
            } else {
                context.insert(StoredTrip(from: trip))
            }
        }

        for stored in existing where !newIDs.contains(stored.id) {
            context.delete(stored)
        }
    }

    private func syncAppState(settings: AppSettings, lastActiveDay: Date?) throws {
        let state = fetchAppState() ?? StoredAppState()
        if fetchAppState() == nil {
            context.insert(state)
        }
        state.apply(settings: settings, lastActiveDay: lastActiveDay)
    }

    private func fetchAppState() -> StoredAppState? {
        let defaultID = StoredAppState.defaultID
        var descriptor = FetchDescriptor<StoredAppState>(
            predicate: #Predicate { $0.singletonID == defaultID }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

enum ExpenseModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            StoredExpense.self,
            StoredFavorite.self,
            StoredTrip.self,
            StoredAppState.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
