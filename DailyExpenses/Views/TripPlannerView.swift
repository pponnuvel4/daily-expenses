import SwiftUI

struct TripPlannerView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showAddTrip = false

    var body: some View {
        NavigationStack {
            List {
                if !store.trips.isEmpty {
                    Section {
                        summaryBanner
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.cyan.opacity(0.08))
                }

                Section {
                    if store.trips.isEmpty {
                        ContentUnavailableView {
                            Label("No trips yet", systemImage: "suitcase.fill")
                        } description: {
                            Text("Create a trip, add spending entries, and see each person's equal share.")
                        } actions: {
                            Button("Plan a trip") {
                                showAddTrip = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.trips) { trip in
                            NavigationLink {
                                TripDetailView(tripID: trip.id)
                            } label: {
                                TripPlanRowView(trip: trip)
                            }
                        }
                        .onDelete { offsets in
                            store.deleteTrips(at: offsets)
                        }
                    }
                } header: {
                    Text("Trip plans")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trip Planner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add trip plan")
                }
            }
            .sheet(isPresented: $showAddTrip) {
                AddTripPlanView()
            }
        }
    }

    private var summaryBanner: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trips saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.trips.count)")
                        .font(.title3.weight(.bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: store.tripsTotalAmount))
                        .font(.title3.weight(.bold))
                }
            }
        }
        .padding()
    }
}

private struct TripPlanRowView: View {
    let trip: TripPlan

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "suitcase.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.cyan.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = trip.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.string(from: trip.sharePerPerson))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.cyan)
                Text("each")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if trip.entryCount > 0 {
            return "\(trip.peopleCount) people • \(trip.entryCount) entries • \(CurrencyFormatter.string(from: trip.totalAmount))"
        }
        if trip.totalAmount > 0 {
            return "\(trip.peopleCount) people • Total \(CurrencyFormatter.string(from: trip.totalAmount))"
        }
        return "\(trip.peopleCount) people • No spending yet"
    }
}

#Preview {
    TripPlannerView()
        .environment(ExpenseStore.preview())
}
