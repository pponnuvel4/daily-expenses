import SwiftUI

struct AppLockView: View {
    let onUnlock: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Daily Expenses Locked")
                .font(.title2.weight(.semibold))

            Text("Use Face ID, Touch ID, or your passcode to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Unlock") {
                Task { await onUnlock() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
