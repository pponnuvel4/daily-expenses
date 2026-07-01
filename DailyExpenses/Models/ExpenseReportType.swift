import Foundation

enum ExpenseReportType: String, CaseIterable, Identifiable {
    case selectedDay
    case selectedDayGroceries
    case selectedDayFarming
    case selectedMonth
    case selectedMonthGroceries
    case selectedMonthFarming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selectedDay: "Day report (all expenses)"
        case .selectedDayGroceries: "Day report (groceries only)"
        case .selectedDayFarming: "Day report (farming only)"
        case .selectedMonth: "Month report (all expenses)"
        case .selectedMonthGroceries: "Month report (groceries only)"
        case .selectedMonthFarming: "Month report (farming only)"
        }
    }

    var categoryFilter: ExpenseCategory? {
        switch self {
        case .selectedDay, .selectedMonth: nil
        case .selectedDayGroceries, .selectedMonthGroceries: .groceries
        case .selectedDayFarming, .selectedMonthFarming: .farming
        }
    }

    var isMonthly: Bool {
        switch self {
        case .selectedDay, .selectedDayGroceries, .selectedDayFarming: false
        case .selectedMonth, .selectedMonthGroceries, .selectedMonthFarming: true
        }
    }
}
