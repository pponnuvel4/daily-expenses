import SwiftUI
import Charts

struct MonthSpendingChartView: View {
    let totals: [CategoryTotal]

    var body: some View {
        Chart(totals) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(item.category.color)
            .cornerRadius(4)
        }
        .frame(height: 220)
    }
}

struct MonthTrendChartView: View {
    let dailyTotals: [DailySpendingTotal]

    var body: some View {
        Chart(dailyTotals) { item in
            BarMark(
                x: .value("Day", item.label),
                y: .value("Spent", item.amount)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
    }
}

struct DailySpendingTotal: Identifiable {
    let id: Date
    let label: String
    let amount: Double
}
