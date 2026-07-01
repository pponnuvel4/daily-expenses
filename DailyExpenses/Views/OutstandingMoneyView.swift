import SwiftUI

struct OutstandingMoneyView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var summaries: [PersonMoneySummary] {
        store.personMoneySummaries()
    }

    private var allOutstanding: [Expense] {
        store.outstandingMoneyEntries()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Given outstanding", value: CurrencyFormatter.string(from: store.allOutstandingGivenTotal()))
                    LabeledContent("Borrowed outstanding", value: CurrencyFormatter.string(from: store.allOutstandingBorrowedTotal()))
                    LabeledContent("Net outstanding", value: CurrencyFormatter.string(from: store.allOutstandingNetTotal()))
                        .font(.headline)
                }

                if summaries.isEmpty {
                    ContentUnavailableView {
                        Label("All settled", systemImage: "checkmark.circle")
                    } description: {
                        Text("No pending money to return or collect.")
                    }
                } else {
                    Section("By person") {
                        ForEach(summaries) { summary in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(summary.name)
                                    .font(.body.weight(.semibold))
                                HStack(spacing: 12) {
                                    if summary.givenOutstanding > 0 {
                                        Label(
                                            CurrencyFormatter.string(from: summary.givenOutstanding),
                                            systemImage: "arrow.up.right"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                    }
                                    if summary.borrowedOutstanding > 0 {
                                        Label(
                                            CurrencyFormatter.string(from: summary.borrowedOutstanding),
                                            systemImage: "arrow.down.left"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Section("All pending entries") {
                        ForEach(allOutstanding) { expense in
                            Button {
                                store.selectedDate = Calendar.current.startOfDay(for: expense.date)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(expense.displayTitle)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text("\(expense.moneyFlowLabel ?? "") • \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(CurrencyFormatter.string(from: expense.amount))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(expense.resolvedMoneyFlow == .given ? .red : .orange)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Outstanding Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
