import Foundation

// MARK: - CustomAction (public registration type)

/// A developer-defined action that appears in the Noober debugger.
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
public struct CustomAction: Sendable {
    public let title: String
    public let icon: String
    public let group: String
    let handler: @Sendable @MainActor () -> Void

    /// Create a custom action.
    /// - Parameters:
    ///   - title: Display name shown in the debugger.
    ///   - icon: SF Symbol name (default: `"bolt.fill"`).
    ///   - group: Optional group header for visual grouping.
    ///   - handler: Closure executed when the action is tapped.
    public init(
        _ title: String,
        icon: String = "bolt.fill",
        group: String = "",
        handler: @escaping @Sendable @MainActor () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.group = group
        self.handler = handler
    }
}

// MARK: - Internal model with identity

struct RegisteredAction: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let group: String
    let handler: @Sendable @MainActor () -> Void

    init(from action: CustomAction) {
        self.id = UUID()
        self.title = action.title
        self.icon = action.icon
        self.group = action.group
        self.handler = action.handler
    }
}
