import Foundation

// MARK: - Priority

public enum QAChecklistPriority: String, Codable, Sendable, CaseIterable, Comparable {
    case high = "HIGH"
    case normal = "NORMAL"
    case low = "LOW"

    private var sortOrder: Int {
        switch self {
        case .high: return 0
        case .normal: return 1
        case .low: return 2
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Status (internal)

enum QAChecklistStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case passed = "PASSED"
    case failed = "FAILED"
}

// MARK: - QAChecklistItem (public registration type)

public struct QAChecklistItem: Sendable {
    public let title: String
    public let notes: String
    public let priority: QAChecklistPriority
    public let endpoints: [String]

    public init(
        _ title: String,
        notes: String = "",
        priority: QAChecklistPriority = .normal,
        endpoints: [String] = []
    ) {
        self.title = title
        self.notes = notes
        self.priority = priority
        self.endpoints = endpoints
    }
}

// MARK: - Persisted result (internal)

struct QAChecklistResult: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let notes: String
    let priority: QAChecklistPriority
    let endpoints: [String]
    var status: QAChecklistStatus
    var failNotes: String
    var attachedRequestIds: [UUID]

    init(from item: QAChecklistItem) {
        self.id = UUID()
        self.title = item.title
        self.notes = item.notes
        self.priority = item.priority
        self.endpoints = item.endpoints
        self.status = .pending
        self.failNotes = ""
        self.attachedRequestIds = []
    }

    init(preservingStatusFrom existing: QAChecklistResult, updatingMetadataFrom item: QAChecklistItem) {
        self.id = existing.id
        self.title = item.title
        self.notes = item.notes
        self.priority = item.priority
        self.endpoints = item.endpoints
        self.status = existing.status
        self.failNotes = existing.failNotes
        self.attachedRequestIds = existing.attachedRequestIds
    }
}
