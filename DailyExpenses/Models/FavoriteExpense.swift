import Foundation

struct FavoriteExpense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory
    ) {
        self.id = id
        self.title = title
        self.amount = max(0.01, amount)
        self.category = category
    }

    var displayName: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? category.title : trimmed
        return "\(name) · \(CurrencyFormatter.string(from: amount))"
    }
}
