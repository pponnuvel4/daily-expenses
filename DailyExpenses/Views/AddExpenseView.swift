import SwiftUI

struct AddExpenseView: View {
    let scope: ExpenseTrackerScope
    @Environment(ExpenseStore.self) private var store

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var priceText = ""
    @State private var quantityText = ""
    @State private var unit = ""
    @State private var priceEntryMode: ExpensePriceEntryMode = .ratePerUnit
    @State private var category: ExpenseCategory
    @State private var moneyFlow: MoneyFlow = .given
    @State private var note = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case amount
        case note
    }

    init(scope: ExpenseTrackerScope) {
        self.scope = scope
        _category = State(initialValue: scope.defaultCategory)
        _unit = State(initialValue: scope.defaultUnit)
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
                    if scope.isMoneyScope {
                        Picker("Type", selection: $moneyFlow) {
                            ForEach(MoneyFlow.allCases) { flow in
                                Text(flow.title).tag(flow)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TextField(scope.isMoneyScope ? moneyFlow.addPrompt : scope.addPrompt, text: $title)
                        .focused($focusedField, equals: .title)

                    if scope.showsQuantityFields {
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

                    if scope.showsCategoryPicker {
                        Picker("Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { item in
                                Label(item.title, systemImage: item.icon).tag(item)
                            }
                        }
                    }

                    TextField(scope.notePlaceholder, text: $note)
                        .focused($focusedField, equals: .note)
                }
            }
            .navigationTitle(scope.addSheetTitle)
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
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(parsedPrice == nil)
                }
            }
        }
    }

    private func addExpense() {
        guard let price = parsedPrice else { return }
        let quantity = scope.showsQuantityFields ? parsedQuantity : nil
        let total = QuantityFormatter.resolveTotal(
            price: price,
            quantity: quantity,
            mode: quantity == nil ? .total : priceEntryMode
        )

        store.addExpense(
            title: title,
            amount: total,
            category: scope.showsCategoryPicker ? category : scope.defaultCategory,
            note: note,
            quantity: quantity,
            unit: scope.showsQuantityFields ? QuantityFormatter.normalizedUnit(unit) : nil,
            moneyFlow: scope.isMoneyScope ? moneyFlow : nil
        )
        dismiss()
    }
}
