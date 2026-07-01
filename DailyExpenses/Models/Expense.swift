import Foundation

struct Expense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var quantity: Double?
    var unit: String?
    var category: ExpenseCategory
    var moneyFlow: MoneyFlow?
    var note: String?
    var date: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        quantity: Double? = nil,
        unit: String? = nil,
        category: ExpenseCategory,
        moneyFlow: MoneyFlow? = nil,
        note: String? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.quantity = quantity
        self.unit = QuantityFormatter.normalizedUnit(unit ?? "")
        self.category = category
        self.moneyFlow = category == .money ? moneyFlow : nil
        self.note = note
        self.date = date
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? category.title : trimmed
    }

    var resolvedMoneyFlow: MoneyFlow? {
        guard category == .money else { return nil }
        return moneyFlow ?? .given
    }

    var quantityLabel: String? {
        guard let quantity else { return nil }
        let value = QuantityFormatter.string(from: quantity)
        if let unit, !unit.isEmpty {
            return "\(value) \(unit)"
        }
        return "Qty \(value)"
    }

    var unitPriceLabel: String? {
        guard let quantity, quantity > 0 else { return nil }
        let unitPrice = amount / quantity
        if let unit, !unit.isEmpty {
            return "\(CurrencyFormatter.string(from: unitPrice)) / \(unit)"
        }
        return "\(CurrencyFormatter.string(from: unitPrice)) each"
    }

    var moneyFlowLabel: String? {
        guard let flow = resolvedMoneyFlow else { return nil }
        return flow.listPrefix
    }
}
