import Foundation

// MARK: - Transferable WebSocket Frame

public struct TransferableWSFrame: Identifiable, Codable, Sendable {
    public let id: UUID
    public let connectionId: UUID
    public let timestamp: Date
    public let direction: String   // "Sent" or "Received"
    public let frameType: String   // "TEXT", "BIN", "PING", "PONG", "CLOSE"
    public let payload: Data?
    public let payloadString: String?

    public init(
        id: UUID,
        connectionId: UUID,
        timestamp: Date,
        direction: String,
        frameType: String,
        payload: Data?,
        payloadString: String?
    ) {
        self.id = id
        self.connectionId = connectionId
        self.timestamp = timestamp
        self.direction = direction
        self.frameType = frameType
        self.payload = payload
        self.payloadString = payloadString
    }
}

// MARK: - Transferable WebSocket Connection

public struct TransferableWSConnection: Identifiable, Codable, Sendable {
    public let id: UUID
    public let url: String
    public let host: String
    public let startTime: Date
    public let status: String      // "Connecting", "Connected", "Disconnected", "Error"
    public let frames: [TransferableWSFrame]
    public let closeCode: Int?
    public let closeReason: String?

    public init(
        id: UUID,
        url: String,
        host: String,
        startTime: Date,
        status: String,
        frames: [TransferableWSFrame],
        closeCode: Int?,
        closeReason: String?
    ) {
        self.id = id
        self.url = url
        self.host = host
        self.startTime = startTime
        self.status = status
        self.frames = frames
        self.closeCode = closeCode
        self.closeReason = closeReason
    }
}
