import Foundation

public struct FullSyncPayload: Codable, Sendable {
    public let httpRequests: [TransferableNetworkRequest]
    public let wsConnections: [TransferableWSConnection]
    public let logEntries: [TransferableLogEntry]
    public let environments: [TransferableEnvironment]
    public let activeEnvironmentId: UUID?
    public let rewriteRules: [TransferableRewriteRule]
    public let mockRules: [TransferableMockRule]
    public let interceptRules: [TransferableInterceptRule]
    public let qaResults: [TransferableQAResult]
    public let buildNumber: String
    public let userDefaultsEntries: [TransferableUserDefaultsEntry]
    public let keychainEntries: [TransferableKeychainEntry]

    public init(
        httpRequests: [TransferableNetworkRequest],
        wsConnections: [TransferableWSConnection],
        logEntries: [TransferableLogEntry],
        environments: [TransferableEnvironment],
        activeEnvironmentId: UUID?,
        rewriteRules: [TransferableRewriteRule],
        mockRules: [TransferableMockRule],
        interceptRules: [TransferableInterceptRule],
        qaResults: [TransferableQAResult],
        buildNumber: String,
        userDefaultsEntries: [TransferableUserDefaultsEntry],
        keychainEntries: [TransferableKeychainEntry]
    ) {
        self.httpRequests = httpRequests
        self.wsConnections = wsConnections
        self.logEntries = logEntries
        self.environments = environments
        self.activeEnvironmentId = activeEnvironmentId
        self.rewriteRules = rewriteRules
        self.mockRules = mockRules
        self.interceptRules = interceptRules
        self.qaResults = qaResults
        self.buildNumber = buildNumber
        self.userDefaultsEntries = userDefaultsEntries
        self.keychainEntries = keychainEntries
    }
}
