import SwiftUI

struct ExportReportView: View {
    @Environment(ExpenseStore.self) private var store
    let defaultReportType: ExpenseReportType

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReportType: ExpenseReportType
    @State private var shareURL: URL?
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
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                    .disabled(reportExpenses.isEmpty)

                    Button {
                        generateAndShareCSV()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    .disabled(reportExpenses.isEmpty)
                } header: {
                    Text("Export")
                } footer: {
                    Text("PDF is best for sharing. CSV opens in Excel or Google Sheets.")
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: cleanupTemporaryFile) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .alert("Export Failed", isPresented: Binding(
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

        shareFile(data: data, fileExtension: "pdf")
    }

    private func generateAndShareCSV() {
        let csv = ExpenseCSVExporter.makeCSV(expenses: reportExpenses, reportTitle: reportTitle)
        guard let data = csv.data(using: .utf8) else {
            errorMessage = "CSV generation failed."
            return
        }
        shareFile(data: data, fileExtension: "csv")
    }

    private func shareFile(data: Data, fileExtension: String) {
        cleanupTemporaryFile()

        let fileName = "Expense-Report-\(selectedReportType.rawValue)-\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            shareURL = url
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cleanupTemporaryFile() {
        if let shareURL {
            try? FileManager.default.removeItem(at: shareURL)
        }
        shareURL = nil
    }
}
