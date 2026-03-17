import Foundation
import Combine

// MARK: - Unified Entry

enum NetworkEntryType: String, CaseIterable, Sendable {
    case http = "HTTP"
    case webSocket = "WebSocket"
}

enum NetworkEntry: Identifiable, Sendable {
    case http(NetworkRequestModel)
    case webSocket(WebSocketConnectionModel)

    var id: UUID {
        switch self {
        case .http(let r): return r.id
        case .webSocket(let c): return c.id
        }
    }

    var timestamp: Date {
        switch self {
        case .http(let r): return r.timestamp
        case .webSocket(let c): return c.startTime
        }
    }

    var entryType: NetworkEntryType {
        switch self {
        case .http: return .http
        case .webSocket: return .webSocket
        }
    }

    var host: String {
        switch self {
        case .http(let r): return r.host
        case .webSocket(let c): return c.host
        }
    }

    var screenName: String? {
        switch self {
        case .http(let r): return r.screenName
        case .webSocket: return nil
        }
    }
}

// MARK: - Store

@MainActor
final class NetworkActivityStore: ObservableObject {

    static let shared = NetworkActivityStore()

    // HTTP
    @Published private(set) var requests: [NetworkRequestModel] = []

    // WebSocket
    @Published private(set) var webSocketConnections: [WebSocketConnectionModel] = []

    // Bubble animation signals
    @Published private(set) var pulseID: UInt = 0
    @Published private(set) var lastRequestSucceeded: Bool = true
    @Published private(set) var activeRequestCount: Int = 0

    private let maxHTTPEntries = 500
    private let maxWSFrames = 1000

    // MARK: - Unified entries

    var allEntries: [NetworkEntry] {
        let httpEntries = requests.map { NetworkEntry.http($0) }
        let wsEntries = webSocketConnections.map { NetworkEntry.webSocket($0) }
        return (httpEntries + wsEntries).sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Screen Grouping

    var uniqueScreenNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for req in requests {
            if let name = req.screenName, !name.isEmpty, seen.insert(name).inserted {
                result.append(name)
            }
        }
        return result
    }

    func entriesGroupedByScreen(from entries: [NetworkEntry]) -> [(screen: String, entries: [NetworkEntry])] {
        var groups: [(screen: String, entries: [NetworkEntry])] = []
        var groupMap: [String: Int] = [:]

        for entry in entries {
            let screen = entry.screenName ?? "Unknown"
            if let idx = groupMap[screen] {
                groups[idx].entries.append(entry)
            } else {
                groupMap[screen] = groups.count
                groups.append((screen: screen, entries: [entry]))
            }
        }
        return groups
    }

    // MARK: - HTTP

    func addRequest(_ model: NetworkRequestModel) {
        requests.insert(model, at: 0)
        if requests.count > maxHTTPEntries {
            requests.removeLast(requests.count - maxHTTPEntries)
        }
        lastRequestSucceeded = model.isSuccess
        pulseID &+= 1
    }

    func trackRequestStarted() {
        activeRequestCount += 1
    }

    func trackRequestFinished() {
        activeRequestCount = max(0, activeRequestCount - 1)
    }

    // MARK: - WebSocket

    func addWebSocketConnection(_ connection: WebSocketConnectionModel, overrideId: UUID) {
        var conn = connection
        // Use the pre-assigned ID from the interceptor
        conn = WebSocketConnectionModel._init(id: overrideId, from: conn)
        webSocketConnections.insert(conn, at: 0)
        pulseID &+= 1
    }

    func addWebSocketFrame(_ frame: WebSocketFrameModel, connectionId: UUID) {
        guard let index = webSocketConnections.firstIndex(where: { $0.id == connectionId }) else { return }
        webSocketConnections[index].frames.append(frame)
        if webSocketConnections[index].frames.count > maxWSFrames {
            webSocketConnections[index].frames.removeFirst(
                webSocketConnections[index].frames.count - maxWSFrames
            )
        }
        // Move connection to top on activity
        let conn = webSocketConnections.remove(at: index)
        webSocketConnections.insert(conn, at: 0)
        pulseID &+= 1
    }

    func updateWebSocketStatus(connectionId: UUID, status: WebSocketConnectionModel.Status) {
        guard let index = webSocketConnections.firstIndex(where: { $0.id == connectionId }) else { return }
        webSocketConnections[index].status = status
    }

    func closeWebSocket(connectionId: UUID, closeCode: Int, reason: String?) {
        guard let index = webSocketConnections.firstIndex(where: { $0.id == connectionId }) else { return }
        webSocketConnections[index].status = .disconnected
        webSocketConnections[index].closeCode = closeCode
        webSocketConnections[index].closeReason = reason
    }

    // MARK: - Clear

    func clearAll() {
        requests.removeAll()
        webSocketConnections.removeAll()
        activeRequestCount = 0
    }

    func clearHTTP() {
        requests.removeAll()
        activeRequestCount = 0
    }

    func clearWebSockets() {
        webSocketConnections.removeAll()
    }

    private init() {}
}

// MARK: - WebSocketConnectionModel internal init helper

extension WebSocketConnectionModel {
    /// Creates a new connection with a specific ID (used by the interceptor).
    static func _init(id: UUID, from source: WebSocketConnectionModel) -> WebSocketConnectionModel {
        return WebSocketConnectionModel(_id: id, url: source.url, host: source.host)
    }

    fileprivate init(_id: UUID, url: String, host: String) {
        self.id = _id
        self.url = url
        self.host = host
        self.startTime = Date()
        self.status = .connecting
        self.frames = []
    }
}
