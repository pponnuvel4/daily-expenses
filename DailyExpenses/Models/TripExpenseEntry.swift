import Foundation

struct TripExpenseEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var note: String?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = max(0, amount)
        self.note = note
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Expense" : trimmed
    }
}
