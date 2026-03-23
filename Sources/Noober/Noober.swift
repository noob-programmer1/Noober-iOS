import SwiftUI

@MainActor
public final class Noober {

    public static let shared = Noober()

    public private(set) var isStarted = false

    /// Start Noober.
    /// - Parameter autoTrackScreens: `true` (default) uses swizzling to auto-detect screen names.
    ///   Set to `false` if your app uses a custom navigation system and you'll call `trackScreen(_:)` manually.
    public func start(autoTrackScreens: Bool = true) {
        guard !isStarted else { return }
        isStarted = true
        if autoTrackScreens {
            ScreenTracker.install()
        }
        NetworkInterceptor.install()
        WebSocketInterceptor.shared.install()
        WebViewInterceptor.install()
        NooberWindow.shared.showBubble()
        CompanionServer.shared.startAdvertising()
    }

    public var isCompanionConnected: Bool { CompanionServer.shared.isConnected }

    public func stop() {
        guard isStarted else { return }
        isStarted = false
        ScreenTracker.uninstall()
        NetworkInterceptor.uninstall()
        WebSocketInterceptor.shared.uninstall()
        NooberWindow.shared.hideBubble()
        CompanionServer.shared.stopAdvertising()
        NetworkActivityStore.shared.clearAll()
        LogStore.shared.clearAll()
        EnvironmentStore.shared.clearAll()
        QAChecklistStore.shared.clearAll()
    }

    // MARK: - Environments

    /// Register available environments for quick switching.
    /// The first environment is the default (no URL rewriting).
    /// Persists the active selection across launches.
    ///
    ///     Noober.shared.registerEnvironments([
    ///         .init(name: "Production", baseURL: "https://api.example.com"),
    ///         .init(name: "Staging", baseURL: "https://api.staging.example.com",
    ///               notes: "Payments won't work. Uses staging API keys."),
    ///     ])
    ///
    public func registerEnvironments(_ environments: [NooberEnvironment]) {
        EnvironmentStore.shared.register(environments)
    }

    // MARK: - QA Checklist

    /// Register a QA checklist for the current build.
    /// Items persist across sessions, keyed by build number.
    /// Calling again with the same build preserves existing pass/fail statuses.
    ///
    ///     Noober.shared.registerChecklist([
    ///         .init("Redesigned checkout", notes: "Test with & without saved cards",
    ///               priority: .high, endpoints: ["/api/v1/payments"]),
    ///         .init("Fixed pull-to-refresh crash"),
    ///     ])
    ///
    public func registerChecklist(_ items: [QAChecklistItem]) {
        QAChecklistStore.shared.register(items)
    }

    // MARK: - Logging

    /// Log a custom message to the Logs tab. Safe to call from any thread.
    ///
    ///     Noober.shared.log("Payment started", category: .analytics)
    ///
    nonisolated public func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .general,
        file: String = #file,
        line: UInt = #line
    ) {
        let entry = LogEntry(level: level, category: category, message: message, file: file, line: line)
        Task { @MainActor in
            guard Self.shared.isStarted else { return }
            LogStore.shared.addEntry(entry)
        }
    }

    // MARK: - Screen Tracking

    /// Manually report the current screen name. Use this when your app has a custom
    /// navigation system (e.g., Coordinator, custom Router) where auto-detection via
    /// swizzling doesn't produce useful names.
    ///
    /// Call this from your navigation controller/router whenever a new screen appears:
    ///
    ///     // In your Navigator/Router:
    ///     func push(_ destination: Destination) {
    ///         // ... push logic ...
    ///         #if DEBUG
    ///         Noober.shared.trackScreen(destination.screenName)
    ///         #endif
    ///     }
    ///
    /// Works alongside auto-detection — manual calls take priority.
    /// Safe to call from any thread.
    nonisolated public func trackScreen(_ name: String) {
        Task { @MainActor in
            guard Self.shared.isStarted else { return }
            ScreenTracker.shared.manualTrack(name)
        }
    }

    // MARK: - Network Configuration

    /// Inject Noober's network interceptor into a URLSessionConfiguration.
    ///
    /// Use this when creating a custom `URLSession` (e.g., Alamofire `Session`)
    /// that might initialize before `Noober.shared.start()` runs, or when
    /// automatic swizzling doesn't cover your session setup.
    ///
    ///     let config = URLSessionConfiguration.default
    ///     #if DEBUG
    ///     Noober.shared.inject(into: config)
    ///     #endif
    ///     let session = Session(configuration: config)
    ///
    nonisolated public func inject(into configuration: URLSessionConfiguration) {
        var protocols = configuration.protocolClasses ?? []
        if !protocols.contains(where: { $0 == NetworkInterceptor.self }) {
            protocols.insert(NetworkInterceptor.self, at: 0)
        }
        configuration.protocolClasses = protocols
    }

    /// Programmatically open the debug panel.
    public func showDebugger() {
        NooberWindow.shared.showDebugger()
    }

    /// Programmatically close the debug panel.
    public func hideDebugger() {
        NooberWindow.shared.hideDebugger()
    }

    private init() {}
}
