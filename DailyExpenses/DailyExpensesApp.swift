import SwiftUI

@main
struct DailyExpensesApp: App {
    @State private var store = ExpenseStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
        }
    }
}
