import Foundation
import SwiftData

@Model
final class StoredExpense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var quantity: Double?
    var unit: String?
    var categoryRaw: String
    var moneyFlowRaw: String?
    var moneyCompleted: Bool
    var note: String?
    var date: Date

    init(from expense: Expense) {
        id = expense.id
        title = expense.title
        amount = expense.amount
        quantity = expense.quantity
        unit = expense.unit
        categoryRaw = expense.category.rawValue
        moneyFlowRaw = expense.moneyFlow?.rawValue
        moneyCompleted = expense.moneyCompleted ?? false
        note = expense.note
        date = expense.date
    }

    func update(from expense: Expense) {
        title = expense.title
        amount = expense.amount
        quantity = expense.quantity
        unit = expense.unit
        categoryRaw = expense.category.rawValue
        moneyFlowRaw = expense.moneyFlow?.rawValue
        moneyCompleted = expense.moneyCompleted ?? false
        note = expense.note
        date = expense.date
    }

    func toExpense() -> Expense {
        Expense(
            id: id,
            title: title,
            amount: amount,
            quantity: quantity,
            unit: unit,
            category: ExpenseCategory(rawValue: categoryRaw) ?? .other,
            moneyFlow: moneyFlowRaw.flatMap { MoneyFlow(rawValue: $0) },
            moneyCompleted: moneyCompleted,
            note: note,
            date: date
        )
    }
}

@Model
final class StoredFavorite {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var quantity: Double?
    var unit: String?
    var categoryRaw: String
    var moneyFlowRaw: String?

    init(from favorite: FavoriteExpense) {
        id = favorite.id
        title = favorite.title
        amount = favorite.amount
        quantity = favorite.quantity
        unit = favorite.unit
        categoryRaw = favorite.category.rawValue
        moneyFlowRaw = favorite.moneyFlow?.rawValue
    }

    func update(from favorite: FavoriteExpense) {
        title = favorite.title
        amount = favorite.amount
        quantity = favorite.quantity
        unit = favorite.unit
        categoryRaw = favorite.category.rawValue
        moneyFlowRaw = favorite.moneyFlow?.rawValue
    }

    func toFavorite() -> FavoriteExpense {
        FavoriteExpense(
            id: id,
            title: title,
            amount: amount,
            quantity: quantity,
            unit: unit,
            category: ExpenseCategory(rawValue: categoryRaw) ?? .other,
            moneyFlow: moneyFlowRaw.flatMap { MoneyFlow(rawValue: $0) }
        )
    }
}

@Model
final class StoredTrip {
    @Attribute(.unique) var id: UUID
    var name: String
    var totalAmount: Double
    var peopleCount: Int
    var note: String?
    var date: Date

    init(from trip: TripPlan) {
        id = trip.id
        name = trip.name
        totalAmount = trip.totalAmount
        peopleCount = trip.peopleCount
        note = trip.note
        date = trip.date
    }

    func update(from trip: TripPlan) {
        name = trip.name
        totalAmount = trip.totalAmount
        peopleCount = trip.peopleCount
        note = trip.note
        date = trip.date
    }

    func toTrip() -> TripPlan {
        TripPlan(
            id: id,
            name: name,
            totalAmount: totalAmount,
            peopleCount: peopleCount,
            note: note,
            date: date
        )
    }
}

@Model
final class StoredAppState {
    @Attribute(.unique) var singletonID: String
    var isAppLockEnabled: Bool
    var monthlyBudget: Double?
    var lastActiveDay: Date?

    init(
        singletonID: String = StoredAppState.defaultID,
        isAppLockEnabled: Bool = false,
        monthlyBudget: Double? = nil,
        lastActiveDay: Date? = nil
    ) {
        self.singletonID = singletonID
        self.isAppLockEnabled = isAppLockEnabled
        self.monthlyBudget = monthlyBudget
        self.lastActiveDay = lastActiveDay
    }

    static let defaultID = "app-state"

    func apply(settings: AppSettings, lastActiveDay: Date?) {
        isAppLockEnabled = settings.isAppLockEnabled
        monthlyBudget = settings.monthlyBudget
        self.lastActiveDay = lastActiveDay
    }

    func toSettings() -> AppSettings {
        AppSettings(isAppLockEnabled: isAppLockEnabled, monthlyBudget: monthlyBudget)
    }
}
