import Foundation

enum ExpenseReportType: String, CaseIterable, Identifiable {
    case selectedDay
    case selectedDayFarming
    case selectedMonth
    case selectedMonthFarming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selectedDay: "Day report (all expenses)"
        case .selectedDayFarming: "Day report (farming only)"
        case .selectedMonth: "Month report (all expenses)"
        case .selectedMonthFarming: "Month report (farming only)"
        }
    }

    var categoryFilter: ExpenseCategory? {
        switch self {
        case .selectedDay, .selectedMonth: nil
        case .selectedDayFarming, .selectedMonthFarming: .farming
        }
    }

    var isMonthly: Bool {
        switch self {
        case .selectedDay, .selectedDayFarming: false
        case .selectedMonth, .selectedMonthFarming: true
        }
    }
}
