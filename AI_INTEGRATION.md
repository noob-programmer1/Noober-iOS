# Noober — AI Integration Reference

> Machine-readable API reference for AI assistants integrating Noober into iOS projects.
> For human documentation, see [README.md](README.md) or the [DocC site](https://noob-programmer1.github.io/Noober-iOS/documentation/noober/).

## Package

```
url: https://github.com/noob-programmer1/Noober-iOS.git
from: "2.0.0"
target dependency: "Noober"
import: Noober
platforms: iOS 15+
swift: 6.0+
dependencies: none
```

## Constraints

- `Noober` class is `@MainActor` — call `start()`, `stop()`, `registerEnvironments()`, `registerChecklist()`, `showDebugger()`, `hideDebugger()` from the main actor only.
- `log()` is `nonisolated` — safe from any thread/actor.
- Always wrap ALL Noober usage in `#if DEBUG` / `#endif`. Noober must never ship in production builds.
- Call `start()` AFTER a `UIWindowScene` exists (e.g., in `ContentView.onAppear` or `AppDelegate.didFinishLaunching`), not in `App.init()` if using SwiftUI lifecycle, because the floating bubble needs an active window scene.

---

## Complete Public API

### Noober (singleton)

```swift
// Access
Noober.shared

// State
Noober.shared.isStarted -> Bool

// Lifecycle
Noober.shared.start()        // Install interceptors, show bubble
Noober.shared.stop()         // Uninstall interceptors, hide bubble, clear data

// Debug panel
Noober.shared.showDebugger() // Open debug panel programmatically
Noober.shared.hideDebugger() // Close debug panel programmatically

// Environments
Noober.shared.registerEnvironments([NooberEnvironment])

// QA Checklist
Noober.shared.registerChecklist([QAChecklistItem])

// Logging (nonisolated, thread-safe)
Noober.shared.log(_ message: String, level: LogLevel = .info, category: LogCategory = .general, file: String = #file, line: UInt = #line)
```

### NooberEnvironment

```swift
// Single base URL
NooberEnvironment(name: String, baseURL: String, notes: String = "")

// Multiple base URLs (positional mapping between environments)
NooberEnvironment(name: String, baseURLs: [String], notes: String = "")

// Properties: id: UUID, name: String, baseURLs: [String], notes: String
// Conforms to: Identifiable, Codable, Sendable, Hashable
```

### QAChecklistItem

```swift
QAChecklistItem(_ title: String, notes: String = "", priority: QAChecklistPriority = .normal, endpoints: [String] = [])

// Properties: title: String, notes: String, priority: QAChecklistPriority, endpoints: [String]
// Conforms to: Sendable
```

### QAChecklistPriority

```swift
// enum QAChecklistPriority: String, Codable, Sendable, CaseIterable, Comparable
.high    // "HIGH"
.normal  // "NORMAL"
.low     // "LOW"
```

### LogLevel

```swift
// enum LogLevel: String, CaseIterable, Sendable, Comparable
.debug   // "DEBUG"
.info    // "INFO"
.warning // "WARN"
.error   // "ERROR"
```

### LogCategory

```swift
// struct LogCategory: RawRepresentable, Hashable, Sendable
LogCategory("analytics")     // Custom category
LogCategory.general          // Built-in default
```

---

## Integration Patterns

### Pattern 1: Minimal (just network inspection)

```swift
#if DEBUG
import Noober
#endif

// In AppDelegate.didFinishLaunching or ContentView.onAppear:
#if DEBUG
Noober.shared.start()
#endif
```

**Result:** All URLSession HTTP/HTTPS and WebSocket traffic is captured automatically. User taps the floating bubble to inspect.

### Pattern 2: With environment switching

```swift
#if DEBUG
import Noober
#endif

#if DEBUG
Noober.shared.registerEnvironments([
    .init(name: "Production", baseURL: "https://api.example.com"),
    .init(name: "Staging", baseURL: "https://api.staging.example.com", notes: "Test keys"),
    .init(name: "Local", baseURL: "http://localhost:8080"),
])
Noober.shared.start()
#endif
```

**Rule:** First environment = default (no URL rewriting). Selecting another rewrites scheme+host+port, preserves path+query.

**Multi-URL variant** (when app talks to multiple servers):

```swift
#if DEBUG
Noober.shared.registerEnvironments([
    .init(name: "Production", baseURLs: ["https://api.example.com", "https://cdn.example.com", "wss://ws.example.com"]),
    .init(name: "Staging", baseURLs: ["https://api.staging.example.com", "https://cdn.staging.example.com", "wss://ws.staging.example.com"]),
])
#endif
```

**Rule:** `baseURLs[0]` of default maps to `baseURLs[0]` of active, and so on positionally.

### Pattern 3: With QA checklist

```swift
#if DEBUG
Noober.shared.registerChecklist([
    .init("Login flow", notes: "Test email + social login", priority: .high, endpoints: ["/auth/login"]),
    .init("Checkout", notes: "Test with & without saved cards", priority: .high, endpoints: ["/api/payments"]),
    .init("Pull-to-refresh", priority: .normal),
    .init("Dark mode", priority: .low),
])
Noober.shared.start()
#endif
```

**Rule:** Items persist per build number (CFBundleVersion). New build auto-resets statuses.

### Pattern 4: Custom logging throughout the app

```swift
// These are nonisolated — safe from any thread, any actor
#if DEBUG
Noober.shared.log("User signed in", level: .info, category: .init("auth"))
Noober.shared.log("API request failed", level: .error, category: .init("network"))
Noober.shared.log("Cache hit ratio: 0.87", level: .debug, category: .init("performance"))
Noober.shared.log("Deprecated API called", level: .warning, category: .init("deprecation"))
#endif
```

### Pattern 5: Full setup (all features)

```swift
#if DEBUG
import Noober
#endif

@main
struct MyApp: App {
    init() {
        #if DEBUG
        Noober.shared.registerEnvironments([
            .init(name: "Production", baseURL: "https://api.example.com"),
            .init(name: "Staging", baseURL: "https://api.staging.example.com"),
        ])
        Noober.shared.registerChecklist([
            .init("Login", priority: .high, endpoints: ["/auth"]),
            .init("Payments", priority: .high, endpoints: ["/pay"]),
        ])
        Noober.shared.start()
        #endif
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

// Anywhere in the app:
#if DEBUG
Noober.shared.log("Event fired", category: .init("analytics"))
#endif
```

---

## What Noober Does Automatically (zero code)

| Feature | How |
|---------|-----|
| Capture all HTTP/HTTPS requests + responses | URLProtocol swizzling on URLSessionConfiguration.default and .ephemeral |
| Capture WebSocket frames | Swizzling URLSessionWebSocketTask methods |
| Tag requests with source screen | Swizzling UIViewController.viewDidAppear |
| Show floating debug bubble | Overlay UIWindow at .alert + 1 level |
| Pretty-print JSON bodies | Automatic detection and formatting |
| Generate cURL commands | From captured request data |
| Persist rules across launches | UserDefaults storage |
| Persist environment selection | UserDefaults storage |
| Persist QA checklist per build | UserDefaults keyed by CFBundleVersion |
| Persist deep link history + favorites | UserDefaults storage |

## What Noober Does NOT Do

- Does NOT intercept requests made with raw sockets or third-party networking libraries that bypass URLSession
- Does NOT modify production builds (you must use `#if DEBUG`)
- Does NOT require any backend, server, or account
- Does NOT add any third-party dependencies to your project
- Does NOT persist captured network requests or logs across app launches (only rules, environments, and QA checklist persist)

---

## Limits

| Resource | Max |
|----------|-----|
| HTTP requests stored | 500 |
| Log entries stored | 500 |
| WebSocket frames per connection | 1000 |
| Screen history entries | 200 |
| Deep link history entries | 100 |

Oldest entries are removed when limits are reached.

---

## File Structure (for context)

```
Sources/Noober/
  Noober.swift                         <- Public API (singleton)
  Core/FloatingBubbleView.swift        <- Draggable bubble overlay
  Core/NooberWindow.swift              <- Window management
  Network/NetworkInterceptor.swift     <- URLProtocol interceptor
  Network/NetworkInterceptor+Swizzle.swift
  Network/NetworkActivityStore.swift   <- Request storage
  Network/RequestReplayer.swift        <- Replay requests
  Network/ScreenTracker.swift          <- VC tracking
  WebSocket/WebSocketInterceptor.swift <- WS capture
  Rules/RulesStore.swift               <- Rule CRUD + persistence
  Rules/InterceptManager.swift         <- Mid-flight intercept
  Rules/Models/{URLMatchPattern, URLRewriteRule, MockRule, InterceptRule, PendingIntercept}.swift
  Environment/EnvironmentStore.swift   <- Env switching + persistence
  Environment/NooberEnvironment.swift  <- Public model
  QAChecklist/QAChecklistStore.swift   <- Checklist + persistence
  QAChecklist/Models/QAChecklistItem.swift <- Public model
  Logs/LogStore.swift                  <- Log storage
  Logs/Models/LogEntry.swift           <- Public models (LogLevel, LogCategory, LogEntry)
  UserDefaults/UserDefaultsStore.swift <- UD browser
  Keychain/KeychainStore.swift         <- Keychain browser
  DeepLink/DeepLinkStore.swift         <- Deep link tester + persistence
  DeepLink/Models/DeepLinkEntry.swift  <- Deep link model (url, result, favorite)
  UI/                                  <- SwiftUI debug panel (all internal)
```

## Deep Link Tester

The deep link tester is available in the **Rules** tab under the **Links** section. It is NOT a public API — users interact with it through the debug panel UI. Deep link history and favorites persist across launches via UserDefaults.

No code integration needed. It works automatically after `Noober.shared.start()`.

## Analytics Logging (recommended pattern)

Noober does NOT have a dedicated analytics API. Use the existing `log()` with a custom category:

```swift
// Define a reusable category
public extension LogCategory {
    static let analytics = LogCategory("Analytics")
}

// In your analytics wrapper:
func track(_ event: String, props: [String: Any]?) {
    #if DEBUG
    let propsString = props.map { "\($0)" } ?? "nil"
    Noober.shared.log("[\(event)] \(propsString)", category: .analytics)
    #endif
    // ... fire to real analytics SDK
}
```

This shows analytics events in the Logs tab, filterable by the "Analytics" category chip.
