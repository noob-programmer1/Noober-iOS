import Foundation

public struct TransferableQAResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let notes: String
    public let priority: String    // "HIGH", "NORMAL", "LOW"
    public let endpoints: [String]
    public var status: String      // "PENDING", "PASSED", "FAILED"
    public var failNotes: String
    public var attachedRequestIds: [UUID]

    public init(
        id: UUID,
        title: String,
        notes: String,
        priority: String,
        endpoints: [String],
        status: String,
        failNotes: String,
        attachedRequestIds: [UUID]
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.endpoints = endpoints
        self.status = status
        self.failNotes = failNotes
        self.attachedRequestIds = attachedRequestIds
    }
}
