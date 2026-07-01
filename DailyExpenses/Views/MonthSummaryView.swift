import SwiftUI

struct CategoryTotal: Identifiable {
    let id: ExpenseCategory
    let category: ExpenseCategory
    let amount: Double
    let percentage: Double
}

struct MonthSummaryView: View {
    @ObservedObject var store: ExpenseStore
    let scope: ExpenseTrackerScope
    @Environment(\.dismiss) private var dismiss

    private var totals: [CategoryTotal] {
        store.categoryTotals(forMonthContaining: store.selectedDate, category: scope.categoryFilter)
    }

    private var monthTotal: Double {
        store.monthTotal(forMonthContaining: store.selectedDate, category: scope.categoryFilter)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Month", value: store.selectedMonthTitle)
                    LabeledContent("Total spent", value: CurrencyFormatter.string(from: monthTotal))
                        .font(.headline)
                }

                if totals.isEmpty {
                    ContentUnavailableView {
                        Label("No expenses", systemImage: "chart.bar")
                    } description: {
                        Text("Nothing recorded for this month yet.")
                    }
                } else {
                    Section("By category") {
                        ForEach(totals) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.category.icon)
                                    .foregroundStyle(item.category.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.category.title)
                                        .font(.body.weight(.medium))
                                    Text("\(Int(item.percentage.rounded()))% of month")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(CurrencyFormatter.string(from: item.amount))
                                    .font(.body.weight(.semibold))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle(scope.monthSummaryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
