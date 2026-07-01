import SwiftUI

struct RootTabView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            ForEach(ExpenseTrackerScope.allCases) { scope in
                ContentView(scope: scope)
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
    RootTabView()
        .environment(ExpenseStore())
}
