import Foundation

public struct CompanionMessage: Codable, Sendable {
    public let type: CompanionMessageType
    public let payload: Data
    public let timestamp: Date

    public init(type: CompanionMessageType, payload: Data) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
    }

    public init(type: CompanionMessageType, payload: Data, timestamp: Date) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
    }

    /// Convenience to create a message with an encodable payload.
    public static func make<T: Codable & Sendable>(
        type: CompanionMessageType,
        payload: T
    ) throws -> CompanionMessage {
        let data = try JSONEncoder().encode(payload)
        return CompanionMessage(type: type, payload: data)
    }

    /// Convenience to decode the payload into a specific type.
    public func decodePayload<T: Codable>(_ payloadType: T.Type) throws -> T {
        try JSONDecoder().decode(payloadType, from: payload)
    }
}
