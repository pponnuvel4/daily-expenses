import SwiftUI

struct AddTripPlanView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var peopleCount = 2
    @State private var note = ""

    private var parsedAmount: Double? {
        QuantityFormatter.parse(amountText)
    }

    private var previewShare: Double? {
        guard let amount = parsedAmount, peopleCount > 0 else { return nil }
        return amount / Double(peopleCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip name", text: $name)
                    TextField("Total amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    Stepper("People: \(peopleCount)", value: $peopleCount, in: 1...100)

                    TextField("Note (optional)", text: $note)
                }

                if let share = previewShare, let amount = parsedAmount {
                    Section("Equal split") {
                        LabeledContent("Total", value: CurrencyFormatter.string(from: amount))
                        LabeledContent("People", value: "\(peopleCount)")
                        LabeledContent("Each person pays", value: CurrencyFormatter.string(from: share))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Plan Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private func saveTrip() {
        guard let amount = parsedAmount else { return }
        store.addTrip(
            name: name,
            totalAmount: amount,
            peopleCount: peopleCount,
            note: note
        )
        dismiss()
    }
}

struct EditTripPlanView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let trip: TripPlan
    @State private var name: String
    @State private var amountText: String
    @State private var peopleCount: Int
    @State private var note: String

    init(trip: TripPlan) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _amountText = State(initialValue: QuantityFormatter.string(from: trip.totalAmount))
        _peopleCount = State(initialValue: trip.peopleCount)
        _note = State(initialValue: trip.note ?? "")
    }

    private var parsedAmount: Double? {
        QuantityFormatter.parse(amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip name", text: $name)
                    TextField("Total amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Stepper("People: \(peopleCount)", value: $peopleCount, in: 1...100)
                    TextField("Note (optional)", text: $note)
                }

                if let amount = parsedAmount {
                    Section("Equal split") {
                        LabeledContent("Each person pays", value: CurrencyFormatter.string(from: amount / Double(peopleCount)))
                            .font(.headline)
                    }
                }

                Section {
                    ShareLink(item: updatedSplitSummary) {
                        Label("Share split", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private var updatedSplitSummary: String {
        let amount = parsedAmount ?? trip.totalAmount
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? "Trip" : trimmedName
        let share = amount / Double(max(1, peopleCount))
        return "\(displayName): \(CurrencyFormatter.string(from: amount)) split among \(peopleCount) people = \(CurrencyFormatter.string(from: share)) each"
    }

    private func saveChanges() {
        guard let amount = parsedAmount else { return }
        var updated = trip
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.totalAmount = amount
        updated.peopleCount = peopleCount
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        store.updateTrip(updated)
        dismiss()
    }
}
