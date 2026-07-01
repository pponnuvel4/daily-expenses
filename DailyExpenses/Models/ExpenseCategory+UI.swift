import SwiftUI

extension ExpenseCategory {
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
        case .money: .indigo
        case .other: .gray
        }
    }
}
