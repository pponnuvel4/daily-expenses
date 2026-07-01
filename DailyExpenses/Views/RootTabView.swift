import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: ExpenseStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            ForEach(ExpenseTrackerScope.allCases) { scope in
                ContentView(store: store, scope: scope)
                    .tabItem {
                        Label(scope.tabTitle, systemImage: scope.tabIcon)
                    }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            _ = store.refreshForNewDayIfNeeded()
        }
    }
}

#Preview {
    RootTabView(store: ExpenseStore())
}
