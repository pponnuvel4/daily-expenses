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
                        Text(expense.category.title)
                        if let note = expense.note, !note.isEmpty {
                            Text("•")
                            Text(note)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(CurrencyFormatter.string(from: expense.amount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
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
}

#Preview {
    List {
        ExpenseRowView(
            expense: Expense(
                title: "Lunch",
                amount: 250,
                category: .food,
                note: "Office canteen"
            )
        )
    }
}
