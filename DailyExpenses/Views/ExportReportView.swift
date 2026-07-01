import SwiftUI

struct ExportReportView: View {
    @Environment(ExpenseStore.self) private var store
    let defaultReportType: ExpenseReportType

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReportType: ExpenseReportType
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    init(defaultReportType: ExpenseReportType) {
        self.defaultReportType = defaultReportType
        _selectedReportType = State(initialValue: defaultReportType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Report type") {
                    Picker("Report", selection: $selectedReportType) {
                        ForEach(ExpenseReportType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Period") {
                    LabeledContent("Based on", value: periodLabel)
                    LabeledContent("Expenses included", value: "\(reportExpenses.count)")
                    LabeledContent("Total", value: CurrencyFormatter.string(from: reportTotal))
                        .font(.headline)
                }

                Section {
                    Button {
                        generateAndSharePDF()
                    } label: {
                        Label("Create PDF and Share", systemImage: "doc.richtext")
                    }
                    .disabled(reportExpenses.isEmpty)
                } footer: {
                    Text("Creates a PDF you can save to Files, print, or send by message or email.")
                }
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: cleanupTemporaryFile) {
                if let pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
            .alert("Could Not Create PDF", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var reportExpenses: [Expense] {
        store.expensesForReport(type: selectedReportType, on: store.selectedDate)
    }

    private var reportTotal: Double {
        store.totalForReport(type: selectedReportType, on: store.selectedDate)
    }

    private var periodLabel: String {
        if selectedReportType.isMonthly {
            return store.selectedMonthTitle
        }
        return store.selectedDayTitle
    }

    private var reportTitle: String {
        selectedReportType.title
    }

    private func generateAndSharePDF() {
        let categoryTotals = selectedReportType.isMonthly
            ? store.categoryTotals(forMonthContaining: store.selectedDate, category: selectedReportType.categoryFilter)
            : []

        guard let data = ExpenseReportPDFGenerator.makePDF(
            reportTitle: reportTitle,
            periodTitle: periodLabel,
            expenses: reportExpenses,
            total: reportTotal,
            categoryTotals: categoryTotals
        ) else {
            errorMessage = "PDF generation failed."
            return
        }

        cleanupTemporaryFile()

        let fileName = "Expense-Report-\(selectedReportType.rawValue)-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            pdfURL = url
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cleanupTemporaryFile() {
        if let pdfURL {
            try? FileManager.default.removeItem(at: pdfURL)
        }
        pdfURL = nil
    }
}
