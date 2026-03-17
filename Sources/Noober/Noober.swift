import SwiftUI

@MainActor
public final class Noober {

    public static let shared = Noober()

    public private(set) var isStarted = false

    public func start() {
        guard !isStarted else { return }
        isStarted = true
        ScreenTracker.install()
        NetworkInterceptor.install()
        WebSocketInterceptor.shared.install()
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
