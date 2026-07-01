import Foundation

struct PersonMoneySummary: Identifiable {
    let id: String
    let name: String
    let givenOutstanding: Double
    let borrowedOutstanding: Double
    let entries: [Expense]

    var netOutstanding: Double {
        borrowedOutstanding - givenOutstanding
    }
}
