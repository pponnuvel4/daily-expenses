import SwiftUI

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var budgetText = ""

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Toggle("Require Face ID / Passcode", isOn: $store.settings.isAppLockEnabled)
                } footer: {
                    Text("Lock the app when it goes to the background.")
                }

                Section("Monthly Budget") {
                    TextField("Budget amount (optional)", text: $budgetText)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            if let budget = store.settings.monthlyBudget {
                                budgetText = QuantityFormatter.string(from: budget)
                            }
                        }
                        .onChange(of: budgetText) { _, newValue in
                            store.settings.monthlyBudget = QuantityFormatter.parse(newValue)
                        }

                    if let budget = store.settings.monthlyBudget, budget > 0 {
                        let spent = store.monthTotal(forMonthContaining: store.selectedDate, category: nil)
                        LabeledContent("Spent this month", value: CurrencyFormatter.string(from: spent))
                        LabeledContent("Remaining", value: CurrencyFormatter.string(from: max(0, budget - spent)))
                    }
                } footer: {
                    Text("Set a monthly spending limit. Progress appears in the month summary on the Daily tab.")
                }

                Section("About") {
                    LabeledContent("Version", value: "2.1 (21)")
                    LabeledContent("Total entries", value: "\(store.expenses.count)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.saveSettings()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                store.saveSettings()
            }
        }
    }
}
