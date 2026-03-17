import Foundation

// MARK: - User Defaults Entry

public struct TransferableUserDefaultsEntry: Identifiable, Codable, Sendable {
    public let id: String
    public let key: String
    public let displayValue: String
    public let valueType: String   // "String", "Int", "Double", "Bool", "Data", "Date", "Array", "Dict", "?"

    public init(
        id: String,
        key: String,
        displayValue: String,
        valueType: String
    ) {
        self.id = id
        self.key = key
        self.displayValue = displayValue
        self.valueType = valueType
    }
}

// MARK: - Keychain Entry

public struct TransferableKeychainEntry: Identifiable, Codable, Sendable {
    public let id: String
    public let itemClass: String   // "Generic" or "Internet"
    public let service: String
    public let account: String
    public let accessGroup: String?
    public let label: String?

    public init(
        id: String,
        itemClass: String,
        service: String,
        account: String,
        accessGroup: String?,
        label: String?
    ) {
        self.id = id
        self.itemClass = itemClass
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
        self.label = label
    }
}
