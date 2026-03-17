import Foundation

enum DeepLinkResult: String, Codable, Sendable {
    case opened
    case failed
}

struct DeepLinkEntry: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var url: String
    var timestamp: Date
    var isFavorite: Bool
    var lastResult: DeepLinkResult?

    init(
        id: UUID = UUID(),
        url: String,
        timestamp: Date = Date(),
        isFavorite: Bool = false,
        lastResult: DeepLinkResult? = nil
    ) {
        self.id = id
        self.url = url
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.lastResult = lastResult
    }
}
