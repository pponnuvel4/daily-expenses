import SwiftData
import SwiftUI

@main
struct DailyExpensesApp: App {
    private let modelContainer: ModelContainer
    @State private var store: ExpenseStore

    init() {
        do {
            let container = try ExpenseModelContainerFactory.makeContainer()
            modelContainer = container
            _store = State(initialValue: ExpenseStore(context: ModelContext(container)))
        } catch {
            fatalError("Failed to create data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
        }
        .modelContainer(modelContainer)
    }
}
