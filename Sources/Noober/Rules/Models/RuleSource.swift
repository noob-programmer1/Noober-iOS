import Foundation

/// Where a rule came from.
///
/// `.manual` rules are created in the debugger UI (or by an AI agent over the
/// companion connection) and persist across launches.
///
/// `.code` rules are registered programmatically via `Noober.shared.registerMocks(_:)`
/// and friends. They are never written to disk — the app re-registers them on every
/// launch, so persisting them would duplicate them forever and leave stale copies
/// behind whenever the code changes.
enum RuleSource: String, Codable, Sendable, Hashable {
    case manual
    case code
}
