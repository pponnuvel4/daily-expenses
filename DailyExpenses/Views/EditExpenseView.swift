import SwiftUI

struct EditExpenseView: View {
    let expense: Expense
    let lockedCategory: ExpenseCategory?
    let showsQuantityFields: Bool
    let isMoneyScope: Bool
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var priceText: String
    @State private var quantityText: String
    @State private var unit: String
    @State private var priceEntryMode: ExpensePriceEntryMode
    @State private var category: ExpenseCategory
    @State private var moneyFlow: MoneyFlow
    @State private var moneyCompleted: Bool
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
        showsQuantityFields: Bool = true,
        isMoneyScope: Bool = false,
        onSave: @escaping (Expense) -> Void
    ) {
        self.expense = expense
        self.lockedCategory = lockedCategory
        self.showsQuantityFields = showsQuantityFields
        self.isMoneyScope = isMoneyScope
        self.onSave = onSave
        _title = State(initialValue: expense.title)
        _priceText = State(
            initialValue: QuantityFormatter.priceTextForEdit(
                total: expense.amount,
                quantity: showsQuantityFields ? expense.quantity : nil,
                mode: showsQuantityFields && expense.quantity != nil ? .ratePerUnit : .total
            )
        )
        _quantityText = State(initialValue: expense.quantity.map { QuantityFormatter.string(from: $0) } ?? "")
        _unit = State(initialValue: expense.unit ?? "")
        _priceEntryMode = State(initialValue: expense.quantity == nil ? .total : .ratePerUnit)
        _category = State(initialValue: lockedCategory ?? expense.category)
        _moneyFlow = State(initialValue: expense.resolvedMoneyFlow ?? .given)
        _moneyCompleted = State(initialValue: expense.isMoneyCompleted)
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
                    if isMoneyScope {
                        Picker("Type", selection: $moneyFlow) {
                            ForEach(MoneyFlow.allCases) { flow in
                                Text(flow.title).tag(flow)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TextField(isMoneyScope ? moneyFlow.addPrompt : "Title", text: $title)
                        .focused($focusedField, equals: .title)

                    if showsQuantityFields {
                        QuantityPriceInputSection(
                            quantityText: $quantityText,
                            unit: $unit,
                            priceText: $priceText,
                            entryMode: $priceEntryMode
                        )
                    } else {
                        TextField("Amount", text: $priceText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
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

                if isMoneyScope {
                    Section {
                        Toggle(moneyFlow.completedStatusLabel, isOn: $moneyCompleted)
                    } footer: {
                        Text(moneyCompleted ? completedFooterText : pendingFooterText)
                    }
                }
            }
            .navigationTitle(isMoneyScope ? "Edit Money Entry" : "Edit Expense")
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
        let quantity = showsQuantityFields ? parsedQuantity : nil
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.amount = QuantityFormatter.resolveTotal(
            price: price,
            quantity: quantity,
            mode: quantity == nil ? .total : priceEntryMode
        )
        updated.quantity = quantity
        updated.unit = showsQuantityFields ? QuantityFormatter.normalizedUnit(unit) : nil
        updated.category = lockedCategory ?? category
        updated.moneyFlow = isMoneyScope ? moneyFlow : nil
        updated.moneyCompleted = isMoneyScope ? moneyCompleted : nil
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        onSave(updated)
        dismiss()
    }

    private var pendingFooterText: String {
        switch moneyFlow {
        case .given: "Turn this on when they return the money to you."
        case .borrowed: "Turn this on after you pay the money back."
        }
    }

    private var completedFooterText: String {
        switch moneyFlow {
        case .given: "Marked as returned to you."
        case .borrowed: "Marked as paid back."
        }
    }
}
