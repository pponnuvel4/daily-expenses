import SwiftUI

struct QuantityPriceInputSection: View {
    @Binding var quantityText: String
    @Binding var unit: String
    @Binding var priceText: String
    @Binding var entryMode: ExpensePriceEntryMode

    private var parsedQuantity: Double? {
        QuantityFormatter.parse(quantityText)
    }

    private var parsedPrice: Double? {
        QuantityFormatter.parse(priceText)
    }

    private var displayUnit: String {
        QuantityFormatter.normalizedUnit(unit) ?? ""
    }

    private var hasQuantity: Bool {
        parsedQuantity != nil
    }

    private var computedTotal: Double? {
        guard let price = parsedPrice else { return nil }
        return QuantityFormatter.resolveTotal(price: price, quantity: parsedQuantity, mode: entryMode)
    }

    private var computedUnitPrice: Double? {
        guard let price = parsedPrice else { return nil }
        return QuantityFormatter.resolveUnitPrice(price: price, quantity: parsedQuantity, mode: entryMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            QuantityInputFields(quantityText: $quantityText, unit: $unit)

            if hasQuantity {
                Picker("Price entry", selection: $entryMode) {
                    ForEach(ExpensePriceEntryMode.allCases) { mode in
                        Text(mode.title(unit: displayUnit.isEmpty ? nil : displayUnit)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            TextField(priceFieldPlaceholder, text: $priceText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            if hasQuantity {
                if entryMode == .ratePerUnit, let computedTotal {
                    priceSummaryRow(
                        title: "Line total",
                        value: CurrencyFormatter.string(from: computedTotal)
                    )
                }

                if entryMode == .total, let computedUnitPrice {
                    let unitLabel = displayUnit.isEmpty ? "unit" : displayUnit
                    priceSummaryRow(
                        title: "Rate per \(unitLabel)",
                        value: CurrencyFormatter.string(from: computedUnitPrice)
                    )
                }
            }
        }
        .onChange(of: entryMode) { oldMode, newMode in
            convertPriceText(from: oldMode, to: newMode)
        }
    }

    private func convertPriceText(from oldMode: ExpensePriceEntryMode, to newMode: ExpensePriceEntryMode) {
        guard oldMode != newMode,
              let quantity = parsedQuantity,
              quantity > 0,
              let price = parsedPrice else { return }

        switch (oldMode, newMode) {
        case (.ratePerUnit, .total):
            priceText = QuantityFormatter.string(from: price * quantity)
        case (.total, .ratePerUnit):
            priceText = QuantityFormatter.string(from: price / quantity)
        default:
            break
        }
    }

    private var priceFieldPlaceholder: String {
        if hasQuantity {
            return entryMode.fieldPlaceholder(unit: displayUnit.isEmpty ? nil : displayUnit)
        }
        return "Amount (total)"
    }

    private func priceSummaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

#Preview {
    QuantityPriceInputSection(
        quantityText: .constant("0.5"),
        unit: .constant("kg"),
        priceText: .constant("540"),
        entryMode: .constant(.ratePerUnit)
    )
    .padding()
}
