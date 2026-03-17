import Foundation

struct MockRule: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let matchPattern: URLMatchPattern
    let httpMethod: String?
    let mockStatusCode: Int
    let mockResponseHeaders: [String: String]
    let mockResponseBody: Data?
    var isEnabled: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        matchPattern: URLMatchPattern,
        httpMethod: String? = nil,
        mockStatusCode: Int = 200,
        mockResponseHeaders: [String: String] = ["Content-Type": "application/json"],
        mockResponseBody: Data? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.matchPattern = matchPattern
        self.httpMethod = httpMethod
        self.mockStatusCode = mockStatusCode
        self.mockResponseHeaders = mockResponseHeaders
        self.mockResponseBody = mockResponseBody
        self.isEnabled = isEnabled
        self.createdAt = createdAt
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
