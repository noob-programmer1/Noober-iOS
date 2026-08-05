import Foundation

// MARK: - URL Matching

/// How a rule's pattern is matched against a request URL.
public enum NooberURLMatch: Sendable {
    /// The URL's host equals the pattern, case-insensitive (`api.example.com`).
    case host
    /// The full URL contains the pattern, case-insensitive (`/api/v1/cart`).
    case contains
    /// The full URL starts with the pattern, case-insensitive.
    case prefix
    /// The full URL equals the pattern.
    case exact
    /// The full URL matches the regular expression.
    case regex

    var mode: URLMatchMode {
        switch self {
        case .host:     return .host
        case .contains: return .contains
        case .prefix:   return .prefix
        case .exact:    return .exact
        case .regex:    return .regex
        }
    }
}

// MARK: - Mock

/// A canned response served instead of hitting the network.
///
///     NooberMock("Empty cart", url: "/api/v1/cart", json: #"{"items": []}"#)
///
///     NooberMock("Payment 500", url: "/api/v1/payments", method: "POST",
///                statusCode: 500, json: #"{"error": "gateway_timeout"}"#)
///
/// Mocks match on the request URL (and optionally the HTTP method). The first
/// enabled mock that matches wins.
public struct NooberMock: Sendable {

    /// Identifies the mock for `Noober.shared.removeMock(id:)`.
    public let id: UUID
    /// Display name shown in the debugger's Mocks tab.
    public let name: String
    /// The pattern matched against the request URL.
    public let url: String
    /// How `url` is matched (default: `.contains`).
    public let match: NooberURLMatch
    /// Restrict to a single HTTP method, e.g. `"POST"`. `nil` matches any method.
    public let method: String?
    /// Status code returned to the caller.
    public let statusCode: Int
    /// Response headers returned to the caller.
    public let headers: [String: String]
    /// Response body returned to the caller.
    public let body: Data?
    /// Whether the mock is active. Register mocks disabled to flip them on
    /// from the debugger UI (or from an AI agent) when a test needs them.
    public let isEnabled: Bool

    /// Create a mock with a raw `Data` body.
    /// - Parameters:
    ///   - name: Display name shown in the debugger.
    ///   - url: Pattern matched against the request URL.
    ///   - match: How `url` is matched (default: `.contains`).
    ///   - method: HTTP method to restrict to, or `nil` for any (default).
    ///   - statusCode: Status code to return (default: `200`).
    ///   - headers: Response headers (default: JSON content type).
    ///   - body: Response body (default: empty).
    ///   - isEnabled: Whether the mock starts active (default: `true`).
    ///   - id: Identifier used to remove the mock later (default: generated).
    public init(
        _ name: String,
        url: String,
        match: NooberURLMatch = .contains,
        method: String? = nil,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        body: Data? = nil,
        isEnabled: Bool = true,
        id: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.match = match
        self.method = method
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.isEnabled = isEnabled
    }

    /// Create a mock with a JSON string body.
    ///
    ///     NooberMock("Empty cart", url: "/api/v1/cart", json: #"{"items": []}"#)
    ///
    public init(
        _ name: String,
        url: String,
        match: NooberURLMatch = .contains,
        method: String? = nil,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        json: String,
        isEnabled: Bool = true,
        id: UUID = UUID()
    ) {
        self.init(
            name,
            url: url,
            match: match,
            method: method,
            statusCode: statusCode,
            headers: headers,
            body: json.data(using: .utf8),
            isEnabled: isEnabled,
            id: id
        )
    }

    func toRule() -> MockRule {
        MockRule(
            id: id,
            name: name,
            matchPattern: URLMatchPattern(mode: match.mode, pattern: url),
            httpMethod: method,
            mockStatusCode: statusCode,
            mockResponseHeaders: headers,
            mockResponseBody: body,
            isEnabled: isEnabled,
            source: .code
        )
    }
}

// MARK: - Intercept

/// A rule that pauses matching requests so they can be inspected — and edited or
/// failed — before they reach the network.
///
///     NooberIntercept("Payments", url: "/api/v1/payments", method: "POST")
///
/// Paused requests surface in the debugger's Intercept tab and over the
/// companion connection, so an AI agent can review them.
public struct NooberIntercept: Sendable {

    /// Identifies the rule for `Noober.shared.removeIntercept(id:)`.
    public let id: UUID
    /// Display name shown in the debugger's Intercept tab.
    public let name: String
    /// The pattern matched against the request URL.
    public let url: String
    /// How `url` is matched (default: `.contains`).
    public let match: NooberURLMatch
    /// Restrict to a single HTTP method, e.g. `"POST"`. `nil` matches any method.
    public let method: String?
    /// Whether the rule is active. Registering disabled is the common case —
    /// pausing every payment call by default would stall the app.
    public let isEnabled: Bool

    /// Create an intercept rule.
    /// - Parameters:
    ///   - name: Display name shown in the debugger.
    ///   - url: Pattern matched against the request URL.
    ///   - match: How `url` is matched (default: `.contains`).
    ///   - method: HTTP method to restrict to, or `nil` for any (default).
    ///   - isEnabled: Whether the rule starts active (default: `true`).
    ///   - id: Identifier used to remove the rule later (default: generated).
    public init(
        _ name: String,
        url: String,
        match: NooberURLMatch = .contains,
        method: String? = nil,
        isEnabled: Bool = true,
        id: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.match = match
        self.method = method
        self.isEnabled = isEnabled
    }

    func toRule() -> InterceptRule {
        InterceptRule(
            id: id,
            name: name,
            matchPattern: URLMatchPattern(mode: match.mode, pattern: url),
            httpMethod: method,
            isEnabled: isEnabled,
            source: .code
        )
    }
}
