import LocalAuthentication
import Observation

@Observable
@MainActor
final class AppLockManager {
    static let shared = AppLockManager()

    private(set) var isUnlocked = true

    private init() {}

    func lockIfNeeded(isEnabled: Bool) {
        guard isEnabled else {
            isUnlocked = true
            return
        }
        isUnlocked = false
    }

    func authenticate(reason: String = "Unlock Daily Expenses") async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            || context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            isUnlocked = success
            return success
        } catch {
            return false
        }
    }
}
