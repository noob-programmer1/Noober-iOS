<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0+-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6.0+" />
  <img src="https://img.shields.io/badge/iOS-15%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 15+" />
  <img src="https://img.shields.io/badge/SPM-Compatible-2ECC71?style=for-the-badge&logo=swift&logoColor=white" alt="SPM Compatible" />
  <img src="https://img.shields.io/badge/Dependencies-Zero-9B59B6?style=for-the-badge" alt="Zero Dependencies" />
</p>

<h1 align="center">Noober</h1>

<p align="center">
  <b>The debugging toolkit your iOS app deserves.</b><br/>
  <sub>Network inspector. Storage browser. Log viewer. Rules engine. QA checklist. One floating bubble.</sub>
</p>

<p align="center">
  <a href="https://noob-programmer1.github.io/Noober-iOS/documentation/noober/">Documentation</a> &bull;
  <a href="#-quick-start">Quick Start</a> &bull;
  <a href="#-installation">Install</a> &bull;
  <a href="#-api-reference">API</a> &bull;
  <a href="LICENSE">License</a>
</p>

---

<p align="center">
  <img src="Screenshots/network.jpg" width="170" alt="Network Inspector" />
  &nbsp;
  <img src="Screenshots/logs.jpg" width="170" alt="Custom Logs" />
  &nbsp;
  <img src="Screenshots/storage.jpg" width="170" alt="Storage Inspector" />
  &nbsp;
  <img src="Screenshots/rules.jpg" width="170" alt="Rules Engine" />
  &nbsp;
  <img src="Screenshots/qa.jpg" width="170" alt="QA Checklist" />
</p>

<p align="center">
  <sub>Network &bull; Logs &bull; Storage &bull; Rules &bull; QA</sub>
</p>

---

## Why Noober?

Drop one line into your debug build and get a complete debugging suite — no Charles Proxy, no separate logging dashboard, no manual environment switching. Just shake or tap the bubble.

```swift
Noober.shared.start()  // That's it.
```

---

> **Using AI to code?** Point your AI assistant (Claude, Cursor, Copilot, etc.) to [`AI_INTEGRATION.md`](AI_INTEGRATION.md) — a machine-readable reference with exact API signatures, copy-paste integration patterns, and constraints. It's designed so any AI can integrate Noober into your project in seconds.

---

## What's Inside

<table>
<tr>
<td width="50%" valign="top">

### Network Inspector
Captures every `URLSession` request automatically — HTTP, HTTPS, and WebSocket. See method, status, headers, body (pretty-printed JSON), timing, size, and the view controller that triggered it. Copy as cURL. Replay with one tap. Filter by method, status, host, or screen.

</td>
<td width="50%" valign="top">

### Rules Engine
**Rewrite** URLs to redirect traffic between servers. **Mock** responses to test edge cases without a backend. **Intercept** requests mid-flight — inspect, edit, then proceed or cancel. Five match modes: Host, Contains, Prefix, Exact, Regex. All rules persist across launches.

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Environment Switching
Register your environments once, switch with one tap. Noober rewrites matching requests automatically. Supports multiple base URLs per environment (API + CDN + WebSocket). Active selection persists across launches.

</td>
<td width="50%" valign="top">

### QA Checklist
Define test items with priority and associated endpoints. Mark pass/fail, attach network requests to failures, track progress. Build-aware — auto-resets when a new build is detected. Share reports.

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Storage Inspector
Browse and edit **UserDefaults** with type-aware parsing. View **Keychain** items with lazy-loaded values. Export UserDefaults as JSON. See app info at a glance.

</td>
<td width="50%" valign="top">

### Custom Logging
Structured logs with four levels (`debug` / `info` / `warning` / `error`) and custom categories. Source file and line captured automatically. Thread-safe — call from anywhere.

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Deep Link Tester
Test any URL scheme or universal link without leaving the app. Input a URL, tap **Fire**, see if it opened or failed. Save **favorites** for reuse. Full **history** with result badges, timestamps, and persistence across launches.

</td>
<td width="50%" valign="top">

### Developer Experience
**Zero dependencies** — pure Swift, no third-party libraries. **One-line setup** — `Noober.shared.start()`. **Swift 6 concurrency** — `@MainActor` stores, `nonisolated` logging, `Sendable` models. **Auto-cleanup** — max 500 requests, 500 logs, 100 deep link history entries.

</td>
</tr>
</table>

---

## Installation

### Swift Package Manager

**Xcode** &rarr; File &rarr; Add Package Dependencies:

```
https://github.com/noob-programmer1/Noober-iOS.git
```

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/noob-programmer1/Noober-iOS.git", from: "2.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["Noober"])
]
```

---

## Quick Start

> [!WARNING]
> Noober is for debugging only. Always wrap with `#if DEBUG`.

### Minimal

```swift
#if DEBUG
import Noober
#endif

@main
struct MyApp: App {
    init() {
        #if DEBUG
        Noober.shared.start()
        #endif
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### Full Power

```swift
#if DEBUG
import Noober
#endif

@main
struct MyApp: App {
    init() {
        #if DEBUG
        // Switch between servers with one tap
        Noober.shared.registerEnvironments([
            .init(name: "Production", baseURL: "https://api.example.com"),
            .init(name: "Staging", baseURL: "https://api.staging.example.com",
                  notes: "Uses test payment keys"),
            .init(name: "Local", baseURL: "http://localhost:8080"),
        ])

        // QA checklist for the current build
        Noober.shared.registerChecklist([
            .init("Login flow", notes: "Test email + social",
                  priority: .high, endpoints: ["/auth/login"]),
            .init("Checkout", notes: "With & without saved cards",
                  priority: .high, endpoints: ["/api/payments"]),
            .init("Pull-to-refresh on feed", priority: .normal),
        ])

        Noober.shared.start()
        #endif
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### Logging

```swift
Noober.shared.log("User signed in")
Noober.shared.log("Payment failed", level: .error, category: .init("payments"))
Noober.shared.log("Cache miss", level: .debug, category: .init("cache"))
```

---

## API Reference

<details>
<summary><b>Noober</b> — Main singleton</summary>

```swift
@MainActor
public final class Noober {
    public static let shared: Noober

    public var isStarted: Bool { get }

    public func start()
    public func stop()
    public func showDebugger()
    public func hideDebugger()

    public func registerEnvironments(_ environments: [NooberEnvironment])
    public func registerChecklist(_ items: [QAChecklistItem])

    // Thread-safe — call from any thread
    nonisolated public func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .general,
        file: String = #file,
        line: UInt = #line
    )
}
```

</details>

<details>
<summary><b>NooberEnvironment</b> — Server environment definition</summary>

```swift
public struct NooberEnvironment: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let baseURLs: [String]
    public let notes: String

    // Single base URL
    public init(name: String, baseURL: String, notes: String = "")

    // Multiple base URLs (positional mapping)
    public init(name: String, baseURLs: [String], notes: String = "")
}
```

</details>

<details>
<summary><b>QAChecklistItem</b> — Test item definition</summary>

```swift
public struct QAChecklistItem: Sendable {
    public let title: String
    public let notes: String
    public let priority: QAChecklistPriority  // .high, .normal, .low
    public let endpoints: [String]

    public init(
        _ title: String,
        notes: String = "",
        priority: QAChecklistPriority = .normal,
        endpoints: [String] = []
    )
}
```

</details>

<details>
<summary><b>LogLevel</b> &amp; <b>LogCategory</b></summary>

```swift
public enum LogLevel: String, CaseIterable, Sendable, Comparable {
    case debug   = "DEBUG"
    case info    = "INFO"
    case warning = "WARN"
    case error   = "ERROR"
}

public struct LogCategory: RawRepresentable, Hashable, Sendable {
    public init(_ rawValue: String)
    public static let general: LogCategory
}
```

</details>

---

## How It Works

| Layer | What it does |
|-------|-------------|
| **URLProtocol swizzling** | Injects `NetworkInterceptor` into `URLSessionConfiguration.default` and `.ephemeral`. Captures all HTTP/HTTPS traffic automatically. |
| **WebSocket swizzling** | Hooks into `URLSessionWebSocketTask` to capture sent/received frames, connection status, and close codes. |
| **Screen tracking** | Swizzles `UIViewController.viewDidAppear(_:)` to tag each request with the source screen. |
| **Rules engine** | Evaluates mock → intercept → environment → rewrite rules in order. Mock/intercept short-circuit. Rules persist in UserDefaults. |
| **Overlay windows** | Bubble lives in a `UIWindow` at `.alert + 1`. Debugger at `.alert + 2`. Custom hit testing passes through non-bubble touches. |
| **Thread safety** | `@MainActor` for all stores. `nonisolated` for logging. `os_unfair_lock` for screen tracker. `NSLock` for rule snapshots read by the interceptor. |

---

## Documentation

Full API docs with guides:

**[noob-programmer1.github.io/Noober-iOS](https://noob-programmer1.github.io/Noober-iOS/documentation/noober/)**

Built with [Swift-DocC](https://www.swift.org/documentation/docc/). Source in `Sources/Noober/Noober.docc/`.

<details>
<summary><b>Build docs locally</b></summary>

```bash
# Build the DocC archive
xcodebuild docbuild \
  -scheme Noober \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .derivedData

# Transform for static hosting
$(xcrun --find docc) process-archive \
  transform-for-static-hosting \
  .derivedData/Build/Products/Debug-iphoneos/Noober.doccarchive \
  --hosting-base-path Noober-iOS \
  --output-path docs
```

Deploy by pushing `docs/` to the `gh-pages` branch. The `.nojekyll` file in the branch root prevents Jekyll from interfering with DocC's SPA routing.

</details>

---

## Requirements

| | Minimum |
|---|---------|
| iOS | 15.0+ |
| Swift | 6.0+ |
| Xcode | 16+ |
| Dependencies | None |

---

<p align="center">
  <sub>Apache 2.0 &mdash; <a href="LICENSE">License</a></sub><br/>
  <sub>Built by <a href="https://github.com/noob-programmer1">Abhishek Agarwal</a></sub>
</p>
