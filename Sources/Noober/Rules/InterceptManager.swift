import Foundation

/// Thread-safe manager that holds intercepted URLProtocol instances until the user acts.
/// Accessed from both the interceptor thread and MainActor (UI).
enum InterceptManager: Sendable {

    private static let lock = NSLock()
    private nonisolated(unsafe) static var pending: [UUID: (interceptor: NetworkInterceptor, tagged: NSMutableURLRequest)] = [:]

    static let autoTimeoutInterval: TimeInterval = 60

    // MARK: - Add

    static func add(id: UUID, interceptor: NetworkInterceptor, tagged: NSMutableURLRequest) {
        lock.lock()
        pending[id] = (interceptor, tagged)
        lock.unlock()

        // Post to UI
        let info = PendingIntercept(
            id: id,
            url: (tagged as URLRequest).url?.absoluteString ?? "unknown",
            method: (tagged as URLRequest).httpMethod ?? "GET",
            host: (tagged as URLRequest).url?.host ?? "unknown",
            path: (tagged as URLRequest).url?.path ?? "/",
            headers: (tagged as URLRequest).allHTTPHeaderFields ?? [:],
            body: (tagged as URLRequest).httpBody ?? (tagged as URLRequest).httpBodyStream?.readAllData(),
            timestamp: Date(),
            autoTimeoutDate: Date().addingTimeInterval(autoTimeoutInterval)
        )

        Task { @MainActor in
            PendingInterceptStore.shared.add(info)
            // Auto-open debugger and switch to Rules tab
            NooberWindow.shared.showDebugger()
            NooberWindow.shared.selectTab(.rules)
        }

        // Auto-timeout: continue with original request after interval
        let capturedId = id
        DispatchQueue.global().asyncAfter(deadline: .now() + autoTimeoutInterval) {
            autoComplete(id: capturedId)
        }
    }

    // MARK: - User Actions

    /// Continue with a (possibly modified) request.
    static func proceed(id: UUID, url: String, method: String, headers: [String: String], body: Data?) {
        lock.lock()
        let entry = pending.removeValue(forKey: id)
        lock.unlock()

        guard let (interceptor, tagged) = entry else { return }

        // Apply modifications
        if let newURL = URL(string: url) {
            tagged.url = newURL
        }
        tagged.httpMethod = method
        // Clear existing headers and set new ones
        if let existingHeaders = tagged.allHTTPHeaderFields {
            for key in existingHeaders.keys {
                tagged.setValue(nil, forHTTPHeaderField: key)
            }
        }
        for (key, value) in headers {
            tagged.setValue(value, forHTTPHeaderField: key)
        }
        if method != "GET" && method != "HEAD" {
            tagged.httpBody = body
        }

        interceptor.proceedWithRequest(tagged as URLRequest)

        Task { @MainActor in
            PendingInterceptStore.shared.remove(id: id)
        }
    }

    /// Continue with original request as-is.
    static func proceedOriginal(id: UUID) {
        lock.lock()
        let entry = pending.removeValue(forKey: id)
        lock.unlock()

        guard let (interceptor, tagged) = entry else { return }
        interceptor.proceedWithRequest(tagged as URLRequest)

        Task { @MainActor in
            PendingInterceptStore.shared.remove(id: id)
        }
    }

    /// Cancel the intercepted request with an error.
    static func cancel(id: UUID) {
        lock.lock()
        let entry = pending.removeValue(forKey: id)
        lock.unlock()

        guard let (interceptor, _) = entry else { return }
        interceptor.cancelInterceptedRequest()

        Task { @MainActor in
            PendingInterceptStore.shared.remove(id: id)
        }
    }

    /// Called from stopLoading() when the original session cancels/times out.
    static func remove(id: UUID) {
        lock.lock()
        pending.removeValue(forKey: id)
        lock.unlock()

        Task { @MainActor in
            PendingInterceptStore.shared.remove(id: id)
        }
    }

    // MARK: - Auto-timeout

    private static func autoComplete(id: UUID) {
        lock.lock()
        let entry = pending.removeValue(forKey: id)
        lock.unlock()

        guard let (interceptor, tagged) = entry else { return }
        interceptor.proceedWithRequest(tagged as URLRequest)

        Task { @MainActor in
            PendingInterceptStore.shared.remove(id: id)
        }
    }
}

// MARK: - PendingInterceptStore (UI observable)

@MainActor
final class PendingInterceptStore: ObservableObject {
    static let shared = PendingInterceptStore()

    @Published private(set) var pendingIntercepts: [PendingIntercept] = []

    private init() {}

    func add(_ intercept: PendingIntercept) {
        pendingIntercepts.insert(intercept, at: 0)
    }

    func remove(id: UUID) {
        pendingIntercepts.removeAll { $0.id == id }
    }
}
