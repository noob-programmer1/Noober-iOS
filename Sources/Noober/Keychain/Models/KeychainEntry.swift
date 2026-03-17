import Foundation

struct KeychainEntry: Identifiable, Sendable, Hashable {
    let id: String  // composite: "\(itemClass.rawValue):\(service):\(account)"
    let itemClass: ItemClass
    let service: String
    let account: String
    let accessGroup: String?
    let createdAt: Date?
    let modifiedAt: Date?
    let label: String?

    enum ItemClass: String, Sendable, CaseIterable {
        case genericPassword = "Generic"
        case internetPassword = "Internet"
    }

    var classAbbreviation: String {
        switch itemClass {
        case .genericPassword: return "GP"
        case .internetPassword: return "IP"
        }
    }

    var modifiedText: String {
        guard let date = modifiedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
