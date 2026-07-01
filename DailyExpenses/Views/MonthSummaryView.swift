import SwiftUI

struct MonthSummaryView: View {
    @Environment(ExpenseStore.self) private var store
    let scope: ExpenseTrackerScope
    @Environment(\.dismiss) private var dismiss

    private var totals: [CategoryTotal] {
        store.categoryTotals(forMonthContaining: store.selectedDate, category: scope.categoryFilter)
    }

    private var monthTotal: Double {
        store.monthTotal(forMonthContaining: store.selectedDate, category: scope.categoryFilter)
    }

    private var monthMoneyExpenses: [Expense] {
        store.expensesForReport(type: .selectedMonthMoney, on: store.selectedDate)
    }

    var body: some View {
        NavigationStack {
            List {
                if scope.isMoneyScope {
                    moneySummaryContent
                } else {
                    standardSummaryContent
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

    @ViewBuilder
    private var moneySummaryContent: some View {
        Section {
            LabeledContent("Month", value: store.selectedMonthTitle)
        }

        Section("Outstanding") {
            LabeledContent("Given", value: CurrencyFormatter.string(from: store.moneyGivenTotal(forMonthContaining: store.selectedDate)))
            LabeledContent("Borrowed", value: CurrencyFormatter.string(from: store.moneyBorrowedTotal(forMonthContaining: store.selectedDate)))
            LabeledContent("Net", value: CurrencyFormatter.string(from: store.moneyNetTotal(forMonthContaining: store.selectedDate)))
                .font(.headline)
        }

        let completedGiven = store.moneyGivenCompletedTotal(forMonthContaining: store.selectedDate)
        let completedBorrowed = store.moneyBorrowedCompletedTotal(forMonthContaining: store.selectedDate)
        if completedGiven > 0 || completedBorrowed > 0 {
            Section("Completed") {
                if completedGiven > 0 {
                    LabeledContent("Returned to me", value: CurrencyFormatter.string(from: completedGiven))
                }
                if completedBorrowed > 0 {
                    LabeledContent("Paid back", value: CurrencyFormatter.string(from: completedBorrowed))
                }
            }
        }

        let monthExpenses = monthMoneyExpenses
        if monthExpenses.isEmpty {
            ContentUnavailableView {
                Label("No entries", systemImage: "banknote")
            } description: {
                Text("No money given or borrowed this month yet.")
            }
        } else {
            Section("This month") {
                ForEach(monthExpenses) { expense in
                    HStack(spacing: 12) {
                        Image(systemName: expense.category.icon)
                            .foregroundStyle(expense.category.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.displayTitle)
                                .font(.body.weight(.medium))
                                .strikethrough(expense.isMoneyCompleted, color: .secondary)
                            HStack(spacing: 6) {
                                if let label = expense.moneyFlowLabel {
                                    Text(label)
                                }
                                if let statusLabel = expense.moneyStatusLabel {
                                    Text("•")
                                    Text(statusLabel)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(CurrencyFormatter.string(from: expense.amount))
                            .font(.body.weight(.semibold))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var standardSummaryContent: some View {
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
}
