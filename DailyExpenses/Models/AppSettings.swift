import Foundation

struct AppSettings: Codable, Equatable {
    var isAppLockEnabled: Bool = false
    var monthlyBudget: Double? = nil
}
