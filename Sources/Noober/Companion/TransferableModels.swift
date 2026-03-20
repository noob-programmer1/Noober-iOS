import Foundation

// MARK: - Network

struct TransferableNetworkRequest: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let url: String
    let host: String
    let path: String
    let method: String
    let requestHeaders: [String: String]
    let requestBody: Data?
    let statusCode: Int?
    let responseHeaders: [String: String]
    let responseBody: Data?
    let duration: TimeInterval
    let errorDescription: String?
    let mimeType: String?
    let isMocked: Bool
    let isIntercepted: Bool
    let isEnvironmentRewritten: Bool
    let originalURL: String?
    let screenName: String?
}

// MARK: - WebSocket

struct TransferableWSConnection: Codable, Sendable {
    let id: UUID
    let url: String
    let host: String
    let startTime: Date
    let status: String
    let frames: [TransferableWSFrame]
    let closeCode: Int?
    let closeReason: String?
}

struct TransferableWSFrame: Codable, Sendable {
    let id: UUID
    let connectionId: UUID
    let timestamp: Date
    let direction: String
    let frameType: String
    let payload: Data?
    let payloadString: String?
}

// MARK: - WebSocket Status Change

struct TransferableWSStatusChange: Codable, Sendable {
    let connectionId: UUID
    let status: String
    let closeCode: Int?
    let closeReason: String?
}

// MARK: - Logs

struct TransferableLogEntry: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: String
    let category: String
    let message: String
    let file: String
    let line: UInt
}

// MARK: - Environment

struct TransferableEnvironment: Codable, Sendable {
    let id: UUID
    let name: String
    let baseURLs: [String]
    let notes: String
}

struct TransferableEnvironmentState: Codable, Sendable {
    let environments: [TransferableEnvironment]
    let activeEnvironmentId: UUID?
}

// MARK: - Rules

struct TransferableURLMatchPattern: Codable, Sendable {
    let mode: String
    let pattern: String
}

struct TransferableRewriteRule: Codable, Sendable {
    let id: UUID
    let name: String
    let matchPattern: TransferableURLMatchPattern
    let replacementHost: String
    let isEnabled: Bool
    let createdAt: Date
}

struct TransferableMockRule: Codable, Sendable {
    let id: UUID
    let name: String
    let matchPattern: TransferableURLMatchPattern
    let httpMethod: String?
    let mockStatusCode: Int
    let mockResponseHeaders: [String: String]
    let mockResponseBody: Data?
    let isEnabled: Bool
    let createdAt: Date
}

struct TransferableInterceptRule: Codable, Sendable {
    let id: UUID
    let name: String
    let matchPattern: TransferableURLMatchPattern
    let httpMethod: String?
    let isEnabled: Bool
    let createdAt: Date
}

struct TransferableRulesState: Codable, Sendable {
    let rewriteRules: [TransferableRewriteRule]
    let mockRules: [TransferableMockRule]
    let interceptRules: [TransferableInterceptRule]
}

// MARK: - QA Checklist

struct TransferableQAResult: Codable, Sendable {
    let id: UUID
    let title: String
    let notes: String
    let priority: String
    let endpoints: [String]
    let status: String
    let failNotes: String
    let attachedRequestIds: [UUID]
}

struct TransferableQAState: Codable, Sendable {
    let results: [TransferableQAResult]
    let buildNumber: String
}

// MARK: - UserDefaults

struct TransferableUserDefaultsEntry: Codable, Sendable {
    let id: String
    let key: String
    let displayValue: String
    let valueType: String
}

// MARK: - Keychain

struct TransferableKeychainEntry: Codable, Sendable {
    let id: String
    let itemClass: String
    let service: String
    let account: String
    let accessGroup: String?
    let createdAt: Date?
    let modifiedAt: Date?
    let label: String?
}

// MARK: - Full Sync Payload

struct FullSyncPayload: Codable, Sendable {
    let httpRequests: [TransferableNetworkRequest]
    let wsConnections: [TransferableWSConnection]
    let logEntries: [TransferableLogEntry]
    let environmentState: TransferableEnvironmentState
    let rulesState: TransferableRulesState
    let qaState: TransferableQAState
    let userDefaultsEntries: [TransferableUserDefaultsEntry]
    let keychainEntries: [TransferableKeychainEntry]
    let currentScreen: String
    let deviceName: String
    let appName: String
    let appVersion: String
    let recordedFlows: [NooberFlow]?
}

// MARK: - Command Payloads

struct SwitchEnvironmentCommand: Codable, Sendable {
    let environmentId: UUID
}

struct ClearStoreCommand: Codable, Sendable {
    let store: String // "http", "websocket", "logs", "rules.rewrite", "rules.mock", "rules.intercept", "userDefaults", "keychain", "qa"
}

struct ToggleRuleCommand: Codable, Sendable {
    let ruleType: String // "rewrite", "mock", "intercept"
    let ruleId: UUID
}

struct ReplayRequestCommand: Codable, Sendable {
    let url: String
    let method: String
    let headers: [String: String]
    let body: Data?
}

struct FireDeepLinkCommand: Codable, Sendable {
    let url: String
}

struct MarkQACommand: Codable, Sendable {
    let itemId: UUID
    let notes: String?
    let requestIds: [UUID]?
}
