import Foundation

// MARK: - URL Match Pattern

public struct TransferableURLMatchPattern: Codable, Sendable, Hashable {
    public let mode: String    // "Host", "Contains", "Prefix", "Exact", "Regex"
    public let pattern: String

    public init(mode: String, pattern: String) {
        self.mode = mode
        self.pattern = pattern
    }
}

// MARK: - URL Rewrite Rule

public struct TransferableRewriteRule: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let matchPattern: TransferableURLMatchPattern
    public let replacementHost: String
    public var isEnabled: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        matchPattern: TransferableURLMatchPattern,
        replacementHost: String,
        isEnabled: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.replacementHost = replacementHost
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

// MARK: - Mock Rule

public struct TransferableMockRule: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let matchPattern: TransferableURLMatchPattern
    public let httpMethod: String?
    public let mockStatusCode: Int
    public let mockResponseHeaders: [String: String]
    public let mockResponseBody: Data?
    public var isEnabled: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        matchPattern: TransferableURLMatchPattern,
        httpMethod: String?,
        mockStatusCode: Int,
        mockResponseHeaders: [String: String],
        mockResponseBody: Data?,
        isEnabled: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.httpMethod = httpMethod
        self.mockStatusCode = mockStatusCode
        self.mockResponseHeaders = mockResponseHeaders
        self.mockResponseBody = mockResponseBody
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

// MARK: - Intercept Rule

public struct TransferableInterceptRule: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let matchPattern: TransferableURLMatchPattern
    public let httpMethod: String?
    public var isEnabled: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        matchPattern: TransferableURLMatchPattern,
        httpMethod: String?,
        isEnabled: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.httpMethod = httpMethod
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}
