import Foundation

enum MoneyFlow: String, Codable, CaseIterable, Identifiable {
    case given
    case borrowed

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "given":
            self = .given
        case "borrowed", "collected":
            self = .borrowed
        default:
            self = .given
        }
    }

    var title: String {
        switch self {
        case .given: "Given"
        case .borrowed: "Borrowed"
        }
    }

    var addPrompt: String {
        switch self {
        case .given: "Who did you give money to?"
        case .borrowed: "Who did you borrow money from?"
        }
    }

    var listPrefix: String {
        switch self {
        case .given: "Given to"
        case .borrowed: "Borrowed from"
        }
    }

    var summaryDescription: String {
        switch self {
        case .given: "Money you lent or gave"
        case .borrowed: "Money you borrowed to return later"
        }
    }
}
