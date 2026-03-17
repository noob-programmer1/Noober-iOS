import Foundation

public struct SwitchEnvironmentCommand: Codable, Sendable {
    public let environmentId: UUID

    public init(environmentId: UUID) {
        self.environmentId = environmentId
    }
}

public struct ClearStoreCommand: Codable, Sendable {
    public let storeName: String

    public init(storeName: String) {
        self.storeName = storeName
    }
}

public struct ToggleRuleCommand: Codable, Sendable {
    public let ruleType: String
    public let ruleId: UUID

    public init(ruleType: String, ruleId: UUID) {
        self.ruleType = ruleType
        self.ruleId = ruleId
    }
}

public struct ReplayRequestCommand: Codable, Sendable {
    public let url: String
    public let method: String
    public let headers: [String: String]
    public let body: Data?

    public init(url: String, method: String, headers: [String: String], body: Data?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

public struct FireDeepLinkCommand: Codable, Sendable {
    public let url: String

    public init(url: String) {
        self.url = url
    }
}

public struct MarkQACommand: Codable, Sendable {
    public let itemId: UUID
    public let notes: String?
    public let requestIds: [UUID]?

    public init(itemId: UUID, notes: String?, requestIds: [UUID]?) {
        self.itemId = itemId
        self.notes = notes
        self.requestIds = requestIds
    }
}

public struct FetchBodyCommand: Codable, Sendable {
    public let requestId: UUID

    public init(requestId: UUID) {
        self.requestId = requestId
    }
}
