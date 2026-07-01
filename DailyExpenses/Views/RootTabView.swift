import SwiftUI

struct RootTabView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var lockManager = AppLockManager.shared

    var body: some View {
        ZStack {
            TabView {
                ForEach(ExpenseTrackerScope.allCases) { scope in
                    ContentView(scope: scope)
                        .tabItem {
                            Label(scope.tabTitle, systemImage: scope.tabIcon)
                        }
                }

                TripPlannerView()
                    .tabItem {
                        Label("Trips", systemImage: "suitcase.fill")
                    }
            }

            if store.settings.isAppLockEnabled && !lockManager.isUnlocked {
                AppLockView {
                    await lockManager.authenticate()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lockManager.isUnlocked)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                if store.settings.isAppLockEnabled {
                    lockManager.lockIfNeeded(isEnabled: true)
                }
            case .active:
                Task {
                    if store.settings.isAppLockEnabled && !lockManager.isUnlocked {
                        await lockManager.authenticate()
                    }
                    _ = store.refreshForNewDayIfNeeded()
                }
            @unknown default:
                break
            }
        }
        .task {
            if store.settings.isAppLockEnabled {
                lockManager.lockIfNeeded(isEnabled: true)
                await lockManager.authenticate()
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(ExpenseStore())
}
