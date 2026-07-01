import SwiftUI

struct AddTripPlanView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var peopleCount = 2
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip name", text: $name)
                    Stepper("People: \(peopleCount)", value: $peopleCount, in: 1...100)
                    TextField("Note (optional)", text: $note)
                } footer: {
                    Text("After saving, add spending entries like hotel, food, and transport. The total and split are calculated automatically.")
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveTrip() {
        store.addTrip(
            name: name,
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
    @State private var peopleCount: Int
    @State private var note: String

    init(trip: TripPlan) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _peopleCount = State(initialValue: trip.peopleCount)
        _note = State(initialValue: trip.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip name", text: $name)
                    Stepper("People: \(peopleCount)", value: $peopleCount, in: 1...100)
                    TextField("Note (optional)", text: $note)
                }

                Section {
                    LabeledContent("Total spent", value: CurrencyFormatter.string(from: trip.totalAmount))
                    LabeledContent("Each person pays", value: CurrencyFormatter.string(from: trip.totalAmount / Double(max(1, peopleCount))))
                        .font(.headline)
                    if trip.entryCount > 0 {
                        LabeledContent("Spending entries", value: "\(trip.entryCount)")
                    }
                } header: {
                    Text("Split")
                } footer: {
                    Text("Edit spending entries from the trip detail screen.")
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
                }
            }
        }
    }

    private var updatedSplitSummary: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? "Trip" : trimmedName
        let share = trip.totalAmount / Double(max(1, peopleCount))
        var summary = "\(displayName): \(CurrencyFormatter.string(from: trip.totalAmount)) split among \(peopleCount) people = \(CurrencyFormatter.string(from: share)) each"

        if !trip.entries.isEmpty {
            summary += "\n\nSpending breakdown:"
            for entry in trip.entries {
                summary += "\n• \(entry.displayTitle): \(CurrencyFormatter.string(from: entry.amount))"
            }
        }

        return summary
    }

    private func saveChanges() {
        var updated = trip
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.peopleCount = peopleCount
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        store.updateTrip(updated)
        dismiss()
    }
}
