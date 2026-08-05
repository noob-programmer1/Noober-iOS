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
        CustomActionStore.shared.clearAll()
        RulesStore.shared.clearCodeRegisteredRules()
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

    // MARK: - Custom Actions

    /// Register custom actions that appear in the debugger's Storage tab.
    /// Useful for quick developer shortcuts like clearing caches or resetting state.
    ///
    ///     Noober.shared.registerActions([
    ///         .init("Clear Cache", icon: "trash", group: "Storage") {
    ///             CacheManager.shared.clearAll()
    ///         },
    ///         .init("Reset Onboarding", icon: "arrow.counterclockwise") {
    ///             UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    ///         },
    ///     ])
    ///
    public func registerActions(_ actions: [CustomAction]) {
        CustomActionStore.shared.register(actions)
    }

    /// Append an action to the ones already registered.
    /// Use this when several feature modules each contribute their own actions
    /// and no single place knows the full list.
    ///
    ///     Noober.shared.addAction(.init("Expire Session", icon: "clock.badge.xmark") {
    ///         AuthManager.shared.expireToken()
    ///     })
    ///
    public func addAction(_ action: CustomAction) {
        CustomActionStore.shared.add([action])
    }

    /// Append actions to the ones already registered.
    public func addActions(_ actions: [CustomAction]) {
        CustomActionStore.shared.add(actions)
    }

    /// Remove every registered action with this title.
    public func removeAction(_ title: String) {
        CustomActionStore.shared.remove(title: title)
    }

    /// Remove all registered actions.
    public func clearActions() {
        CustomActionStore.shared.clearAll()
    }

    // MARK: - Mocks

    /// Register mock responses that ship with the build.
    ///
    ///     Noober.shared.registerMocks([
    ///         .init("Empty cart", url: "/api/v1/cart", json: #"{"items": []}"#),
    ///         .init("Payment failure", url: "/api/v1/payments", method: "POST",
    ///               statusCode: 500, json: #"{"error": "gateway_timeout"}"#,
    ///               isEnabled: false),
    ///     ])
    ///
    /// Registering replaces any mocks registered from code previously — the array
    /// you pass is the full set — so calling this on every launch never
    /// accumulates duplicates. Mocks created by hand in the debugger are left
    /// alone and take precedence over these when both match a request.
    ///
    /// Code-registered mocks are not persisted; the app re-creates them each launch.
    /// Pass `isEnabled: false` to register a mock in the off position and flip it on
    /// from the debugger UI when a test needs it.
    public func registerMocks(_ mocks: [NooberMock]) {
        RulesStore.shared.registerCodeMockRules(mocks.map { $0.toRule() })
    }

    /// Add a single mock at the top of the list, above every existing rule.
    ///
    /// Use this to mock something mid-session — from a test hook or a custom
    /// action — when `registerMocks(_:)`'s replace-everything behaviour is wrong.
    ///
    /// - Returns: The mock's id, for `removeMock(id:)`.
    @discardableResult
    public func addMock(_ mock: NooberMock) -> UUID {
        RulesStore.shared.addMockRule(mock.toRule())
        return mock.id
    }

    /// Remove a mock by id, whether it was added from code or created in the debugger.
    public func removeMock(id: UUID) {
        RulesStore.shared.deleteMockRule(id: id)
    }

    // MARK: - Intercepts

    /// Register intercept rules that pause matching requests for review before
    /// they hit the network.
    ///
    ///     Noober.shared.registerIntercepts([
    ///         .init("Payments", url: "/api/v1/payments", method: "POST", isEnabled: false),
    ///     ])
    ///
    /// Same semantics as `registerMocks(_:)`: the array is the full set of
    /// code-registered rules, rules created in the debugger are untouched, and
    /// nothing is persisted.
    ///
    /// Registering with `isEnabled: false` is usually what you want — a rule that
    /// pauses every payment call from launch will stall the app.
    public func registerIntercepts(_ intercepts: [NooberIntercept]) {
        RulesStore.shared.registerCodeInterceptRules(intercepts.map { $0.toRule() })
    }

    /// Add a single intercept rule at the top of the list, above every existing rule.
    /// - Returns: The rule's id, for `removeIntercept(id:)`.
    @discardableResult
    public func addIntercept(_ intercept: NooberIntercept) -> UUID {
        RulesStore.shared.addInterceptRule(intercept.toRule())
        return intercept.id
    }

    /// Remove an intercept rule by id, whether it was added from code or created
    /// in the debugger.
    public func removeIntercept(id: UUID) {
        RulesStore.shared.deleteInterceptRule(id: id)
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
