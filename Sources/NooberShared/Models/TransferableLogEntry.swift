import Foundation

public struct TransferableLogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: String      // "DEBUG", "INFO", "WARN", "ERROR"
    public let category: String
    public let message: String
    public let file: String
    public let line: UInt
    public let screenName: String?

    public init(
        id: UUID,
        timestamp: Date,
        level: String,
        category: String,
        message: String,
        file: String,
        line: UInt,
        screenName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.line = line
        self.screenName = screenName
    }
}
