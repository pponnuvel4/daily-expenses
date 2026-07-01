import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case groceries
    case transport
    case shopping
    case bills
    case health
    case entertainment
    case farming
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: "Food"
        case .groceries: "Groceries"
        case .transport: "Transport"
        case .shopping: "Shopping"
        case .bills: "Bills"
        case .health: "Health"
        case .entertainment: "Fun"
        case .farming: "Farming"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .bills: "doc.text.fill"
        case .health: "heart.fill"
        case .entertainment: "gamecontroller.fill"
        case .farming: "leaf.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .groceries: .teal
        case .transport: .blue
        case .shopping: .purple
        case .bills: .red
        case .health: .pink
        case .entertainment: .green
        case .farming: .brown
        case .other: .gray
        }
    }
}
