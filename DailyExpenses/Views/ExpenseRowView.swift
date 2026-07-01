import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var onTap: (() -> Void)?
    var onAddFavorite: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: expense.category.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(expense.category.color.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.displayTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        if let moneyFlowLabel = expense.moneyFlowLabel {
                            Text(moneyFlowLabel)
                        } else {
                            Text(expense.category.title)
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
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onAddFavorite {
                Button {
                    onAddFavorite()
                } label: {
                    Label("Add to favorites", systemImage: "star")
                }
            }
        }
    }

    private var amountColor: Color {
        switch expense.resolvedMoneyFlow {
        case .given: .red
        case .collected: .green
        case nil: .primary
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
