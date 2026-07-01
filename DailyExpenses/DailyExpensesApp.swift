import SwiftUI

@main
struct DailyExpensesApp: App {
    @StateObject private var store = ExpenseStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
        }
    }
}
