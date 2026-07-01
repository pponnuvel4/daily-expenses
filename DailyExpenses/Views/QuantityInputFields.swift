import SwiftUI

struct QuantityInputFields: View {
    @Binding var quantityText: String
    @Binding var unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Qty", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 90)

                TextField("Unit (kg, pcs)", text: $unit)
                    .textFieldStyle(.roundedBorder)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuantityFormatter.commonUnits, id: \.self) { commonUnit in
                        Button(commonUnit) {
                            unit = commonUnit
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(unit == commonUnit ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    QuantityInputFields(
        quantityText: .constant("2"),
        unit: .constant("kg")
    )
    .padding()
}
