import Foundation

public struct TransferableNetworkRequest: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let url: String
    public let host: String
    public let path: String
    public let method: String
    public let requestHeaders: [String: String]
    public let requestBody: Data?
    public let statusCode: Int?
    public let responseHeaders: [String: String]
    public let responseBody: Data?
    public let duration: TimeInterval
    public let errorDescription: String?
    public let mimeType: String?
    public let isMocked: Bool
    public let isIntercepted: Bool
    public let isEnvironmentRewritten: Bool
    public let originalURL: String?
    public let screenName: String?

    // MARK: - Computed Helpers

    public var isSuccess: Bool {
        guard let code = statusCode else { return false }
        return (200..<300).contains(code)
    }

    public var durationText: String {
        let ms = duration * 1000
        if ms < 1000 {
            return String(format: "%.0fms", ms)
        } else {
            return String(format: "%.1fs", duration)
        }
    }

    public var responseSizeText: String {
        guard let data = responseBody else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)
    }

    // MARK: - Init

    public init(
        id: UUID,
        timestamp: Date,
        url: String,
        host: String,
        path: String,
        method: String,
        requestHeaders: [String: String],
        requestBody: Data?,
        statusCode: Int?,
        responseHeaders: [String: String],
        responseBody: Data?,
        duration: TimeInterval,
        errorDescription: String?,
        mimeType: String?,
        isMocked: Bool,
        isIntercepted: Bool,
        isEnvironmentRewritten: Bool,
        originalURL: String?,
        screenName: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.host = host
        self.path = path
        self.method = method
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.duration = duration
        self.errorDescription = errorDescription
        self.mimeType = mimeType
        self.isMocked = isMocked
        self.isIntercepted = isIntercepted
        self.isEnvironmentRewritten = isEnvironmentRewritten
        self.originalURL = originalURL
        self.screenName = screenName
    }
}
