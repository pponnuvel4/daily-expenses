import SwiftUI

struct EditExpenseView: View {
    let expense: Expense
    let lockedCategory: ExpenseCategory?
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amountText: String
    @State private var quantityText: String
    @State private var unit: String
    @State private var category: ExpenseCategory
    @State private var note: String
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case amount
        case note
    }

    init(
        expense: Expense,
        lockedCategory: ExpenseCategory? = nil,
        onSave: @escaping (Expense) -> Void
    ) {
        self.expense = expense
        self.lockedCategory = lockedCategory
        self.onSave = onSave
        _title = State(initialValue: expense.title)
        _amountText = State(initialValue: Self.formatAmount(expense.amount))
        _quantityText = State(initialValue: expense.quantity.map { QuantityFormatter.string(from: $0) } ?? "")
        _unit = State(initialValue: expense.unit ?? "")
        _category = State(initialValue: lockedCategory ?? expense.category)
        _note = State(initialValue: expense.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    QuantityInputFields(quantityText: $quantityText, unit: $unit)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { item in
                            Label(item.title, systemImage: item.icon).tag(item)
                        }
                    }
                    .disabled(lockedCategory != nil)
                    TextField("Note (optional)", text: $note)
                        .focused($focusedField, equals: .note)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private var parsedAmount: Double? {
        let normalized = amountText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.amount = amount
        updated.quantity = QuantityFormatter.parse(quantityText)
        updated.unit = QuantityFormatter.normalizedUnit(unit)
        updated.category = lockedCategory ?? category
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        onSave(updated)
        dismiss()
    }

    private static func formatAmount(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
