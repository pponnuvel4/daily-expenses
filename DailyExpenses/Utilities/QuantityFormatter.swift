import Foundation

enum QuantityFormatter {
    static let commonUnits = ["pcs", "kg", "g", "L", "ml", "bags", "bunches"]

    static func string(from value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    static func parse(_ text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    static func normalizedUnit(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// When quantity is set, the entered price is treated as rate per unit.
    static func totalAmount(unitPrice: Double, quantity: Double?) -> Double {
        guard let quantity, quantity > 0 else { return unitPrice }
        return unitPrice * quantity
    }

    static func unitPrice(total: Double, quantity: Double?) -> Double {
        guard let quantity, quantity > 0 else { return total }
        return total / quantity
    }

    static func resolveTotal(price: Double, quantity: Double?, mode: ExpensePriceEntryMode) -> Double {
        guard let quantity, quantity > 0 else { return price }
        switch mode {
        case .ratePerUnit:
            return price * quantity
        case .total:
            return price
        }
    }

    static func resolveUnitPrice(price: Double, quantity: Double?, mode: ExpensePriceEntryMode) -> Double? {
        guard let quantity, quantity > 0 else { return nil }
        switch mode {
        case .ratePerUnit:
            return price
        case .total:
            return price / quantity
        }
    }

    static func priceTextForEdit(total: Double, quantity: Double?, mode: ExpensePriceEntryMode) -> String {
        switch mode {
        case .ratePerUnit:
            return string(from: unitPrice(total: total, quantity: quantity))
        case .total:
            return string(from: total)
        }
    }

    static func amountFieldLabel(hasQuantity: Bool, unit: String?, preferRateLabel: Bool = false) -> String {
        guard hasQuantity || preferRateLabel else { return "Amount (total)" }
        if let unit, !unit.isEmpty {
            return "Rate (per \(unit))"
        }
        return "Rate (per unit)"
    }
}
