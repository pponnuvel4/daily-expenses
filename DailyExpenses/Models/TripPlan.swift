import Foundation

struct TripPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var peopleCount: Int
    var note: String?
    var date: Date
    var entries: [TripExpenseEntry]
    private var legacyTotalAmount: Double

    init(
        id: UUID = UUID(),
        name: String,
        peopleCount: Int,
        note: String? = nil,
        date: Date = Date(),
        entries: [TripExpenseEntry] = [],
        legacyTotalAmount: Double = 0
    ) {
        self.id = id
        self.name = name
        self.peopleCount = max(1, peopleCount)
        self.note = note
        self.date = date
        self.entries = entries
        self.legacyTotalAmount = max(0, legacyTotalAmount)
    }

    init(
        id: UUID = UUID(),
        name: String,
        totalAmount: Double,
        peopleCount: Int,
        note: String? = nil,
        date: Date = Date()
    ) {
        self.init(
            id: id,
            name: name,
            peopleCount: peopleCount,
            note: note,
            date: date,
            entries: [],
            legacyTotalAmount: totalAmount
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, name, peopleCount, note, date, entries, totalAmount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        peopleCount = try container.decode(Int.self, forKey: .peopleCount)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        date = try container.decode(Date.self, forKey: .date)
        entries = try container.decodeIfPresent([TripExpenseEntry].self, forKey: .entries) ?? []
        legacyTotalAmount = try container.decodeIfPresent(Double.self, forKey: .totalAmount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(peopleCount, forKey: .peopleCount)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(date, forKey: .date)
        try container.encode(entries, forKey: .entries)
        try container.encode(totalAmount, forKey: .totalAmount)
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Trip" : trimmed
    }

    var totalAmount: Double {
        if !entries.isEmpty {
            return entries.reduce(0) { $0 + $1.amount }
        }
        return legacyTotalAmount
    }

    var sharePerPerson: Double {
        guard peopleCount > 0 else { return 0 }
        return totalAmount / Double(peopleCount)
    }

    var entryCount: Int {
        entries.count
    }

    var splitSummary: String {
        var lines = [
            "\(displayName): \(CurrencyFormatter.string(from: totalAmount)) split among \(peopleCount) people = \(CurrencyFormatter.string(from: sharePerPerson)) each"
        ]

        if !entries.isEmpty {
            lines.append("")
            lines.append("Spending breakdown:")
            for entry in entries {
                lines.append("• \(entry.displayTitle): \(CurrencyFormatter.string(from: entry.amount))")
            }
        }

        return lines.joined(separator: "\n")
    }
}
