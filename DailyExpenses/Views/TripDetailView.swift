import SwiftUI

struct TripDetailView: View {
    @Environment(ExpenseStore.self) private var store

    let tripID: UUID
    @State private var showAddEntry = false
    @State private var entryToEdit: TripExpenseEntry?
    @State private var showEditTrip = false

    private var trip: TripPlan? {
        store.trip(with: tripID)
    }

    var body: some View {
        Group {
            if let trip {
                tripContent(trip)
            } else {
                ContentUnavailableView("Trip not found", systemImage: "suitcase")
            }
        }
        .navigationTitle(trip?.displayName ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditTrip = true
                    } label: {
                        Label("Edit trip", systemImage: "pencil")
                    }

                    if let trip {
                        ShareLink(item: trip.splitSummary) {
                            Label("Share split", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddTripExpenseEntryView(tripID: tripID)
        }
        .sheet(item: $entryToEdit) { entry in
            EditTripExpenseEntryView(tripID: tripID, entry: entry)
        }
        .sheet(isPresented: $showEditTrip) {
            if let trip {
                EditTripPlanView(trip: trip)
            }
        }
    }

    @ViewBuilder
    private func tripContent(_ trip: TripPlan) -> some View {
        List {
            Section {
                summaryBanner(for: trip)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.cyan.opacity(0.08))

            Section {
                if trip.entries.isEmpty {
                    ContentUnavailableView {
                        Label("No spending yet", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Add what you spent on — hotel, food, transport, shopping, and more.")
                    } actions: {
                        Button("Add spending") {
                            showAddEntry = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(trip.entries) { entry in
                        TripExpenseEntryRow(entry: entry) {
                            entryToEdit = entry
                        }
                    }
                    .onDelete { offsets in
                        store.deleteTripEntries(tripID: tripID, at: offsets)
                    }
                }
            } header: {
                Text("Spending")
            } footer: {
                if !trip.entries.isEmpty {
                    Text("Total is calculated from these entries. Each person's share updates automatically.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .bottomTrailing) {
            if !trip.entries.isEmpty {
                Button {
                    showAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.cyan.gradient, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .padding()
                .accessibilityLabel("Add spending")
            }
        }
    }

    private func summaryBanner(for trip: TripPlan) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: trip.totalAmount))
                        .font(.title2.weight(.bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("People")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(trip.peopleCount)")
                        .font(.title2.weight(.bold))
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Each person pays")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: trip.sharePerPerson))
                        .font(.title.weight(.bold))
                        .foregroundStyle(.cyan)
                }

                Spacer()

                if trip.entryCount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(trip.entryCount)")
                            .font(.title3.weight(.semibold))
                    }
                }
            }

            if let note = trip.note, !note.isEmpty {
                Divider()
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}

private struct TripExpenseEntryRow: View {
    let entry: TripExpenseEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if let note = entry.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)

                Text(CurrencyFormatter.string(from: entry.amount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AddTripExpenseEntryView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let tripID: UUID
    @State private var title = ""
    @State private var amountText = ""
    @State private var note = ""

    private var parsedAmount: Double? {
        QuantityFormatter.parse(amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What did you spend on?", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                } footer: {
                    Text("Examples: Hotel, Dinner, Petrol, Shopping, Entry tickets")
                }
            }
            .navigationTitle("Add Spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(parsedAmount == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        guard let amount = parsedAmount else { return }
        store.addTripEntry(
            to: tripID,
            title: title,
            amount: amount,
            note: note
        )
        dismiss()
    }
}

struct EditTripExpenseEntryView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let tripID: UUID
    let entry: TripExpenseEntry

    @State private var title: String
    @State private var amountText: String
    @State private var note: String

    init(tripID: UUID, entry: TripExpenseEntry) {
        self.tripID = tripID
        self.entry = entry
        _title = State(initialValue: entry.title)
        _amountText = State(initialValue: QuantityFormatter.string(from: entry.amount))
        _note = State(initialValue: entry.note ?? "")
    }

    private var parsedAmount: Double? {
        QuantityFormatter.parse(amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What did you spend on?", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Edit Spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(parsedAmount == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        guard let amount = parsedAmount else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = entry
        updated.title = trimmedTitle
        updated.amount = amount
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        store.updateTripEntry(in: tripID, entry: updated)
        dismiss()
    }
}
