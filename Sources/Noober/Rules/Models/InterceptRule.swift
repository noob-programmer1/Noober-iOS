import Foundation

struct InterceptRule: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let matchPattern: URLMatchPattern
    let httpMethod: String?
    var isEnabled: Bool
    let createdAt: Date
    /// Not persisted — code-registered rules are re-created on every launch.
    var source: RuleSource = .manual

    private enum CodingKeys: String, CodingKey {
        case id, name, matchPattern, httpMethod, isEnabled, createdAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        matchPattern: URLMatchPattern,
        httpMethod: String? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        source: RuleSource = .manual
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.httpMethod = httpMethod
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.source = source
    }

    func matches(_ request: URLRequest) -> Bool {
        guard isEnabled,
              let url = request.url,
              matchPattern.matches(url) else { return false }
        if let method = httpMethod {
            return request.httpMethod?.uppercased() == method.uppercased()
        }
        return true
    }
}
