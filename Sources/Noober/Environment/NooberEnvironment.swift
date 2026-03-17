import Foundation

public struct NooberEnvironment: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let baseURLs: [String]
    public let notes: String

    /// Multiple base URLs — positional mapping across environments.
    ///
    ///     .init(name: "Staging", baseURLs: [
    ///         "https://api.staging.example.com",
    ///         "https://cdn.staging.example.com",
    ///     ])
    ///
    public init(
        id: UUID = UUID(),
        name: String,
        baseURLs: [String],
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.baseURLs = baseURLs
        self.notes = notes
    }

    /// Convenience for a single base URL.
    public init(
        id: UUID = UUID(),
        name: String,
        baseURL: String,
        notes: String = ""
    ) {
        self.init(id: id, name: name, baseURLs: [baseURL], notes: notes)
    }
}
