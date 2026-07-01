import Foundation

struct TripPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var totalAmount: Double
    var peopleCount: Int
    var note: String?
    var date: Date

    init(
        id: UUID = UUID(),
        name: String,
        totalAmount: Double,
        peopleCount: Int,
        note: String? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.totalAmount = max(0, totalAmount)
        self.peopleCount = max(1, peopleCount)
        self.note = note
        self.date = date
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Trip" : trimmed
    }

    var sharePerPerson: Double {
        guard peopleCount > 0 else { return 0 }
        return totalAmount / Double(peopleCount)
    }

    var splitSummary: String {
        "\(displayName): \(CurrencyFormatter.string(from: totalAmount)) split among \(peopleCount) people = \(CurrencyFormatter.string(from: sharePerPerson)) each"
    }
}
