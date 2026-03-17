import Foundation

struct PendingIntercept: Identifiable, Sendable {
    let id: UUID
    let url: String
    let method: String
    let host: String
    let path: String
    let headers: [String: String]
    let body: Data?
    let timestamp: Date
    let autoTimeoutDate: Date
}
