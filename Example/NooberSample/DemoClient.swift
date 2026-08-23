import Foundation
import Combine

/// Drives traffic against `Example/demo_server.py` running on the host machine.
/// The simulator reaches the host over 127.0.0.1.
final class DemoClient: ObservableObject {

    static let httpBase = "http://127.0.0.1:8765"
    static let wsURL = URL(string: "ws://127.0.0.1:8766")!

    @Published private(set) var status = "Idle"
    @Published private(set) var isConnected = false

    private var task: URLSessionWebSocketTask?
    private var chatTimer: Timer?

    // MARK: - HTTP

    func sendHTTP(path: String, method: String = "GET", body: [String: Any]? = nil) {
        guard let url = URL(string: Self.httpBase + path) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            DispatchQueue.main.async {
                self?.status = error.map { "HTTP error: \($0.localizedDescription)" }
                    ?? "\(method) \(path) → \(code) (\(data?.count ?? 0) bytes)"
            }
        }.resume()
    }

    /// Fires several requests at once so the bubble's in-flight arc is visible.
    func sendBurst() {
        for i in 1...6 {
            sendHTTP(path: "/slow?n=\(i)")
        }
    }

    // MARK: - WebSocket

    func connect() {
        disconnect()
        let task = URLSession.shared.webSocketTask(with: Self.wsURL)
        self.task = task
        task.resume()
        receiveNext()
        DispatchQueue.main.async {
            self.isConnected = true
            self.status = "WebSocket connecting…"
        }
    }

    func disconnect() {
        chatTimer?.invalidate()
        chatTimer = nil
        task?.cancel(with: .goingAway, reason: "Sample app closed it".data(using: .utf8))
        task = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.status = "WebSocket closed"
        }
    }

    private func receiveNext() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    switch message {
                    case .string(let text): self.status = "Received \(text.count) chars"
                    case .data(let data):   self.status = "Received \(data.count) bytes (binary)"
                    @unknown default:       self.status = "Received frame"
                    }
                }
                self.receiveNext()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.status = "WS receive failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func sendSmallText() {
        send(.string("ping from sample app"))
    }

    /// The payload that used to be unreadable: a long, deeply nested JSON blob.
    func sendBigJSON() {
        let payload: [String: Any] = [
            "type": "booking.update",
            "requestId": UUID().uuidString,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "passenger": [
                "id": 88213,
                "name": "Ada Lovelace",
                "phone": "+91 90000 00000",
                "tags": ["premium", "corporate", "early-adopter"]
            ],
            "trip": [
                "route": "Powai → Lower Parel",
                "seats": ["1A", "1B", "2C"],
                "fare": ["base": 249.0, "surge": 1.4, "taxes": 44.82, "total": 393.42],
                "stops": (1...12).map { ["seq": $0, "name": "Stop \($0)", "eta": "0\($0 % 9 + 1):15"] }
            ],
            "notes": String(repeating: "This frame is deliberately long so the detail view has to scroll. ", count: 8)
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        send(.string(text))
    }

    func sendBinary() {
        var bytes = Data("NOOBER-BIN".utf8)
        bytes.append(contentsOf: (0..<80).map { UInt8($0 % 256) })
        send(.data(bytes))
    }

    /// Sends a message every 2s so frames stream in while the detail view is open.
    func toggleAutoChat() {
        if let timer = chatTimer {
            timer.invalidate()
            chatTimer = nil
            status = "Auto chat off"
            return
        }
        chatTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.sendBigJSON()
        }
        status = "Auto chat on"
    }

    private func send(_ message: URLSessionWebSocketTask.Message) {
        guard let task = task else {
            status = "Connect the WebSocket first"
            return
        }
        task.send(message) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async { self?.status = "WS send failed: \(error.localizedDescription)" }
            }
        }
    }
}
