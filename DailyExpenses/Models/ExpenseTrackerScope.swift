import Foundation

enum ExpenseTrackerScope: String, CaseIterable, Identifiable {
    case daily
    case farming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily Expenses"
        case .farming: "Farming Expenses"
        }
    }

    var tabTitle: String {
        switch self {
        case .daily: "Daily"
        case .farming: "Farming"
        }
    }

    var tabIcon: String {
        switch self {
        case .daily: "indianrupeesign.circle.fill"
        case .farming: "leaf.fill"
        }
    }

    var categoryFilter: ExpenseCategory? {
        switch self {
        case .daily: nil
        case .farming: .farming
        }
    }

    var defaultCategory: ExpenseCategory {
        switch self {
        case .daily: .food
        case .farming: .farming
        }
    }

    var showsCategoryPicker: Bool {
        switch self {
        case .daily: true
        case .farming: false
        }
    }

    var addPrompt: String {
        switch self {
        case .daily: "What did you spend on?"
        case .farming: "What farm expense was this?"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .daily: "Add what you spent on"
        case .farming: "Add a farming expense for"
        }
    }
}
