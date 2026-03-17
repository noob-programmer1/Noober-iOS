import Foundation

struct URLRewriteRule: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let matchPattern: URLMatchPattern
    let replacementHost: String
    var isEnabled: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        matchPattern: URLMatchPattern,
        replacementHost: String,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.replacementHost = replacementHost
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    /// Returns the rewritten URL if this rule matches, nil otherwise.
    func apply(to url: URL) -> URL? {
        guard isEnabled, matchPattern.matches(url) else { return nil }

        if matchPattern.mode == .host {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
            // replacementHost may be "api.staging.com" or "api.staging.com:8080"
            let parts = replacementHost.split(separator: ":", maxSplits: 1)
            components.host = String(parts[0])
            if parts.count > 1, let port = Int(parts[1]) {
                components.port = port
            }
            return components.url
        } else {
            let rewritten = url.absoluteString.replacingOccurrences(of: matchPattern.pattern, with: replacementHost)
            return URL(string: rewritten)
        }
    }
}
