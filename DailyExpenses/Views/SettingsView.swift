import SwiftUI

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var budgetText = ""
    @State private var showRestoreSuccess = false
    @State private var restoredCount = 0

    private var monthlySpent: Double {
        store.monthTotal(forMonthContaining: store.selectedDate, category: nil)
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Toggle("Require Face ID / Passcode", isOn: $store.settings.isAppLockEnabled)
                } footer: {
                    Text("Lock the app when it goes to the background.")
                }

                Section {
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
                        LabeledContent("Spent this month", value: CurrencyFormatter.string(from: monthlySpent))
                        LabeledContent("Remaining", value: CurrencyFormatter.string(from: max(0, budget - monthlySpent)))
                    }
                } header: {
                    Text("Monthly Budget")
                } footer: {
                    Text("Set a monthly spending limit. Progress appears in the month summary on the Daily tab.")
                }

                Section {
                    LabeledContent("Version", value: "2.2 (24)")
                    LabeledContent("Total entries", value: "\(store.expenses.count)")
                } header: {
                    Text("About")
                }

                if store.hasRecoverableData {
                    Section {
                        Button {
                            restoredCount = store.restorePersistedData()
                            showRestoreSuccess = restoredCount > 0
                        } label: {
                            Label("Restore saved data", systemImage: "arrow.clockwise.circle")
                        }
                    } footer: {
                        Text("Found \(store.recoverableRecordCount) saved entries in backup or previous storage. Tap to restore.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Data Restored", isPresented: $showRestoreSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Restored \(restoredCount) saved entries.")
            }
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
