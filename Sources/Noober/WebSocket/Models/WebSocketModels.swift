import Foundation

// MARK: - WebSocket Frame

struct WebSocketFrameModel: Identifiable, Sendable {
    let id: UUID
    let connectionId: UUID
    let timestamp: Date
    let direction: Direction
    let frameType: FrameType
    let payload: Data?
    let payloadString: String?

    var payloadPreview: String {
        if let str = payloadString {
            return str.count > 120 ? String(str.prefix(120)) + "..." : str
        }
        if let data = payload {
            return "(binary, \(data.count) bytes)"
        }
        return "(empty)"
    }

    var isJSON: Bool {
        guard let str = payloadString?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return (str.hasPrefix("{") && str.hasSuffix("}"))
            || (str.hasPrefix("[") && str.hasSuffix("]"))
    }

    var prettyPayload: String {
        if isJSON, let data = payloadString?.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return payloadString ?? payload.flatMap { String(data: $0, encoding: .utf8) } ?? "(binary)"
    }

    var sizeText: String {
        let bytes = payload?.count ?? payloadString?.utf8.count ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    enum Direction: String, Sendable, CaseIterable {
        case sent = "Sent"
        case received = "Received"
    }

    enum FrameType: String, Sendable {
        case text = "TEXT"
        case binary = "BIN"
        case ping = "PING"
        case pong = "PONG"
        case close = "CLOSE"
    }

    init(connectionId: UUID, direction: Direction, frameType: FrameType, payload: Data?, payloadString: String?) {
        self.id = UUID()
        self.connectionId = connectionId
        self.timestamp = Date()
        self.direction = direction
        self.frameType = frameType
        self.payload = payload
        self.payloadString = payloadString
    }
}

// MARK: - WebSocket Connection

struct WebSocketConnectionModel: Identifiable, Sendable {
    let id: UUID
    let url: String
    let host: String
    let startTime: Date
    var status: Status
    var frames: [WebSocketFrameModel]
    var closeCode: Int?
    var closeReason: String?

    var lastActivityTime: Date {
        frames.last?.timestamp ?? startTime
    }

    var sentCount: Int {
        frames.filter { $0.direction == .sent }.count
    }

    var receivedCount: Int {
        frames.filter { $0.direction == .received }.count
    }

    var displayName: String {
        if let urlObj = URL(string: url) {
            return urlObj.path.isEmpty || urlObj.path == "/" ? host : urlObj.path
        }
        return host
    }

    enum Status: String, Sendable {
        case connecting = "Connecting"
        case connected = "Connected"
        case disconnected = "Disconnected"
        case error = "Error"
    }

    init(url: String) {
        self.id = UUID()
        self.url = url
        self.host = URL(string: url)?.host ?? "unknown"
        self.startTime = Date()
        self.status = .connecting
        self.frames = []
    }
}
