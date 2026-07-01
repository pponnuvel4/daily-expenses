import Foundation

enum MoneyFlow: String, Codable, CaseIterable, Identifiable {
    case given
    case collected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .given: "Given"
        case .collected: "Collected"
        }
    }

    var addPrompt: String {
        switch self {
        case .given: "Who did you give money to?"
        case .collected: "Who did you collect money from?"
        }
    }

    var listPrefix: String {
        switch self {
        case .given: "Given to"
        case .collected: "Collected from"
        }
    }
}
