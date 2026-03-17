import Foundation

public struct TransferableEnvironment: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let baseURLs: [String]
    public let notes: String

    public init(
        id: UUID,
        name: String,
        baseURLs: [String],
        notes: String
    ) {
        self.id = id
        self.name = name
        self.baseURLs = baseURLs
        self.notes = notes
    }
}
