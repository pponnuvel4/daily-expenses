import SwiftUI

enum ExpenseTrackerScope: String, CaseIterable, Identifiable {
    case daily
    case groceries
    case farming
    case money

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily Expenses"
        case .groceries: "Groceries"
        case .farming: "Farming Expenses"
        case .money: "Money"
        }
    }

    var tabTitle: String {
        switch self {
        case .daily: "Daily"
        case .groceries: "Groceries"
        case .farming: "Farming"
        case .money: "Money"
        }
    }

    var tabIcon: String {
        switch self {
        case .daily: "indianrupeesign.circle.fill"
        case .groceries: "cart.fill"
        case .farming: "leaf.fill"
        case .money: "banknote.fill"
        }
    }

    var categoryFilter: ExpenseCategory? {
        switch self {
        case .daily: nil
        case .groceries: .groceries
        case .farming: .farming
        case .money: .money
        }
    }

    var defaultCategory: ExpenseCategory {
        switch self {
        case .daily: .food
        case .groceries: .groceries
        case .farming: .farming
        case .money: .money
        }
    }

    var showsCategoryPicker: Bool {
        switch self {
        case .daily: true
        case .groceries, .farming, .money: false
        }
    }

    var showsQuantityFields: Bool {
        switch self {
        case .daily, .money: false
        case .groceries, .farming: true
        }
    }

    var isMoneyScope: Bool {
        self == .money
    }

    var addPrompt: String {
        switch self {
        case .daily: "What did you spend on?"
        case .groceries: "What grocery item was this?"
        case .farming: "What farm expense was this?"
        case .money: "Person name"
        }
    }

    var notePlaceholder: String {
        switch self {
        case .money: "Reason (optional)"
        default: "Note (optional)"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .daily: "Add what you spent on"
        case .groceries: "Add a grocery item for"
        case .farming: "Add a farming expense for"
        case .money: "Record money given or borrowed on"
        }
    }

    var defaultUnit: String {
        switch self {
        case .daily, .money: ""
        case .groceries: "pcs"
        case .farming: "kg"
        }
    }

    var listBannerColor: Color {
        switch self {
        case .daily: Color.accentColor.opacity(0.08)
        case .groceries: Color.teal.opacity(0.08)
        case .farming: Color.brown.opacity(0.08)
        case .money: Color.indigo.opacity(0.08)
        }
    }

    var monthSummaryTitle: String {
        switch self {
        case .daily: "Month Summary"
        case .groceries: "Groceries Summary"
        case .farming: "Farming Summary"
        case .money: "Money Summary"
        }
    }

    var addSheetTitle: String {
        switch self {
        case .daily: "Add Expense"
        case .groceries: "Add Grocery Item"
        case .farming: "Add Farming Expense"
        case .money: "Record Money"
        }
    }
}
