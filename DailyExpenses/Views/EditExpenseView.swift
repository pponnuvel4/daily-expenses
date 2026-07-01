import SwiftUI

struct EditExpenseView: View {
    let expense: Expense
    let lockedCategory: ExpenseCategory?
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var priceText: String
    @State private var quantityText: String
    @State private var unit: String
    @State private var priceEntryMode: ExpensePriceEntryMode
    @State private var category: ExpenseCategory
    @State private var note: String
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
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
        _priceText = State(
            initialValue: QuantityFormatter.priceTextForEdit(
                total: expense.amount,
                quantity: expense.quantity,
                mode: expense.quantity == nil ? .total : .ratePerUnit
            )
        )
        _quantityText = State(initialValue: expense.quantity.map { QuantityFormatter.string(from: $0) } ?? "")
        _unit = State(initialValue: expense.unit ?? "")
        _priceEntryMode = State(initialValue: expense.quantity == nil ? .total : .ratePerUnit)
        _category = State(initialValue: lockedCategory ?? expense.category)
        _note = State(initialValue: expense.note ?? "")
    }

    private var parsedQuantity: Double? {
        QuantityFormatter.parse(quantityText)
    }

    private var parsedPrice: Double? {
        QuantityFormatter.parse(priceText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                    QuantityPriceInputSection(
                        quantityText: $quantityText,
                        unit: $unit,
                        priceText: $priceText,
                        entryMode: $priceEntryMode
                    )
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
                    .disabled(parsedPrice == nil)
                }
            }
        }
    }

    private func save() {
        guard let price = parsedPrice else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantity = parsedQuantity
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.amount = QuantityFormatter.resolveTotal(
            price: price,
            quantity: quantity,
            mode: quantity == nil ? .total : priceEntryMode
        )
        updated.quantity = quantity
        updated.unit = QuantityFormatter.normalizedUnit(unit)
        updated.category = lockedCategory ?? category
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        onSave(updated)
        dismiss()
    }
}
