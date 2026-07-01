import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var onTap: (() -> Void)?
    var onAddFavorite: (() -> Void)?
    var onToggleCompleted: (() -> Void)?
    var onDuplicate: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: rowIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(expense.category.color.gradient, in: Circle())
                    .opacity(expense.isMoneyCompleted ? 0.5 : 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.displayTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(expense.isMoneyCompleted ? .secondary : .primary)
                        .strikethrough(expense.isMoneyCompleted, color: .secondary)

                    HStack(spacing: 6) {
                        if let moneyFlowLabel = expense.moneyFlowLabel {
                            Text(moneyFlowLabel)
                        } else {
                            Text(expense.category.title)
                        }
                        if let statusLabel = expense.moneyStatusLabel {
                            Text("•")
                            Text(statusLabel)
                                .foregroundStyle(expense.isMoneyCompleted ? .green : .orange)
                        }
                        if let quantityLabel = expense.quantityLabel {
                            Text("•")
                            Text(quantityLabel)
                        }
                        if let note = expense.note, !note.isEmpty {
                            Text("•")
                            Text(note)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let unitPriceLabel = expense.unitPriceLabel {
                        Text(unitPriceLabel)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 8)

                Text(CurrencyFormatter.string(from: expense.amount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(amountColor)
                    .strikethrough(expense.isMoneyCompleted, color: .secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onToggleCompleted, expense.resolvedMoneyFlow != nil {
                Button {
                    onToggleCompleted()
                } label: {
                    if let flow = expense.resolvedMoneyFlow {
                        Label(
                            flow.markCompletedLabel(isCompleted: expense.isMoneyCompleted),
                            systemImage: expense.isMoneyCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                        )
                    }
                }
            }

            if let onDuplicate {
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
            }

            if let onAddFavorite {
                Button {
                    onAddFavorite()
                } label: {
                    Label("Add to favorites", systemImage: "star")
                }
            }
        }
    }

    private var rowIcon: String {
        if expense.isMoneyCompleted {
            return "checkmark.circle.fill"
        }
        return expense.category.icon
    }

    private var amountColor: Color {
        if expense.isMoneyCompleted {
            return .secondary
        }
        switch expense.resolvedMoneyFlow {
        case .given:
            return .red
        case .borrowed:
            return .orange
        case nil:
            return .primary
        }
    }
}

#Preview {
    List {
        ExpenseRowView(
            expense: Expense(
                title: "Coconut",
                amount: 270,
                quantity: 6,
                unit: "pcs",
                category: .food,
                note: "Market"
            )
        )
    }
}
