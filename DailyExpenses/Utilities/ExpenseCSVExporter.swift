import Foundation

enum ExpenseCSVExporter {
    static func makeCSV(expenses: [Expense], reportTitle: String) -> String {
        var lines = ["Report,\(csvEscape(reportTitle))"]
        lines.append("Date,Title,Category,Amount,Quantity,Unit,Money Flow,Status,Note")

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        for expense in expenses {
            let date = formatter.string(from: expense.date)
            let quantity = expense.quantity.map { QuantityFormatter.string(from: $0) } ?? ""
            let unit = expense.unit ?? ""
            let moneyFlow = expense.resolvedMoneyFlow?.title ?? ""
            let status = expense.moneyStatusLabel ?? ""
            let note = expense.note ?? ""

            lines.append([
                csvEscape(date),
                csvEscape(expense.displayTitle),
                csvEscape(expense.category.title),
                String(format: "%.2f", expense.amount),
                csvEscape(quantity),
                csvEscape(unit),
                csvEscape(moneyFlow),
                csvEscape(status),
                csvEscape(note)
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
