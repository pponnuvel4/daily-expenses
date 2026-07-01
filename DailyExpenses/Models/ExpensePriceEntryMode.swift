import Foundation

enum ExpensePriceEntryMode: String, CaseIterable, Identifiable, Codable {
    case ratePerUnit
    case total

    var id: String { rawValue }

    func title(unit: String?) -> String {
        switch self {
        case .ratePerUnit:
            if let unit, !unit.isEmpty {
                return "Rate per \(unit)"
            }
            return "Rate per unit"
        case .total:
            return "Total paid"
        }
    }

    func fieldPlaceholder(unit: String?) -> String {
        switch self {
        case .ratePerUnit:
            if let unit, !unit.isEmpty {
                return "Rate (per \(unit))"
            }
            return "Rate (per unit)"
        case .total:
            return "Total paid"
        }
    }
}
