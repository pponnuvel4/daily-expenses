import Foundation

struct FavoriteExpense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var quantity: Double?
    var unit: String?
    var category: ExpenseCategory

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        quantity: Double? = nil,
        unit: String? = nil,
        category: ExpenseCategory
    ) {
        self.id = id
        self.title = title
        self.amount = max(0.01, amount)
        self.quantity = quantity
        self.unit = QuantityFormatter.normalizedUnit(unit ?? "")
        self.category = category
    }

    var displayName: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? category.title : trimmed
        if let quantityLabel = quantityLabel {
            return "\(name) · \(quantityLabel) · \(CurrencyFormatter.string(from: amount))"
        }
        return "\(name) · \(CurrencyFormatter.string(from: amount))"
    }

    private var quantityLabel: String? {
        guard let quantity else { return nil }
        let value = QuantityFormatter.string(from: quantity)
        if let unit, !unit.isEmpty {
            return "\(value) \(unit)"
        }
        return "Qty \(value)"
    }
}
