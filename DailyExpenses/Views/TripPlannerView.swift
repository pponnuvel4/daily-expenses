import SwiftUI

struct TripPlannerView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showAddTrip = false
    @State private var tripToEdit: TripPlan?

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
                            Text("Plan a trip, enter the total cost and number of people, and see each person's equal share.")
                        } actions: {
                            Button("Plan a trip") {
                                showAddTrip = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.trips) { trip in
                            TripPlanRowView(trip: trip) {
                                tripToEdit = trip
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
            .sheet(item: $tripToEdit) { trip in
                EditTripPlanView(trip: trip)
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
                    Text("Total planned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: store.tripsTotalAmount))
                        .font(.title3.weight(.bold))
                }
            }

            if store.trips.count == 1, let trip = store.trips.first {
                Divider()
                HStack {
                    Text("Each person pays")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.string(from: trip.sharePerPerson))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.cyan)
                }
            }
        }
        .padding()
    }
}

private struct TripPlanRowView: View {
    let trip: TripPlan
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                    Text("\(trip.peopleCount) people • Total \(CurrencyFormatter.string(from: trip.totalAmount))")
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            ShareLink(item: trip.splitSummary) {
                Label("Share split", systemImage: "square.and.arrow.up")
            }
        }
    }
}

#Preview {
    TripPlannerView()
        .environment(ExpenseStore())
}
