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
        _amountText = State(
            initialValue: Self.formatAmount(
                QuantityFormatter.unitPrice(total: expense.amount, quantity: expense.quantity)
            )
        )
        _quantityText = State(initialValue: expense.quantity.map { QuantityFormatter.string(from: $0) } ?? "")
        _unit = State(initialValue: expense.unit ?? "")
        _category = State(initialValue: lockedCategory ?? expense.category)
        _note = State(initialValue: expense.note ?? "")
    }

    private var parsedQuantity: Double? {
        QuantityFormatter.parse(quantityText)
    }

    private var displayUnit: String {
        QuantityFormatter.normalizedUnit(unit) ?? "kg"
    }

    private var amountFieldPlaceholder: String {
        QuantityFormatter.amountFieldLabel(
            hasQuantity: parsedQuantity != nil,
            unit: displayUnit.isEmpty ? nil : displayUnit,
            preferRateLabel: parsedQuantity != nil
        )
    }

    private var computedLineTotal: Double? {
        guard let rate = parsedAmount else { return nil }
        guard let quantity = parsedQuantity else { return nil }
        return QuantityFormatter.totalAmount(unitPrice: rate, quantity: quantity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                    QuantityInputFields(quantityText: $quantityText, unit: $unit)
                    TextField(amountFieldPlaceholder, text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    if parsedQuantity != nil, parsedAmount != nil {
                        Text("Enter price per \(displayUnit), not the full total.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let computedLineTotal {
                        LabeledContent("Line total", value: CurrencyFormatter.string(from: computedLineTotal))
                    }
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
        guard let enteredPrice = parsedAmount else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantity = parsedQuantity
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.amount = QuantityFormatter.totalAmount(unitPrice: enteredPrice, quantity: quantity)
        updated.quantity = quantity
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
