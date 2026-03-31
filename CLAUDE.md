# Noober — iOS Debugging & QA SDK

Noober is an in-app debugging SDK for iOS. When integrated, it gives AI agents (like Claude) deep visibility into the running app.

## Quick Integration

```swift
// Package.swift — add dependency
.package(url: "https://github.com/aspect-build/noober-ios", from: "1.0.0")

// App init — one line
#if DEBUG
import Noober
Noober.shared.start()
#endif
```

That's it. The app now exposes network requests, logs, analytics events, screen layout, and more to AI agents via NooberMCP.

## What Noober Gives AI Agents

Once integrated, Claude (via NooberMCP) can:

| Capability | Tool | Speed |
|-----------|------|-------|
| Read screen layout as HTML | `noober_screen_html` | ~100ms |
| Find element by text | `noober_find_element` | ~50ms |
| Read visible text | `noober_screen_text` | ~50ms |
| Check current screen name | `noober_current_screen` | instant |
| Verify API call made correctly | `noober_assert_request` | instant |
| Check if analytics event fired | `noober_check_event` | instant |
| Read a specific UI value | `noober_get_value` | instant |
| See all network requests | `noober_get_network_logs` | fast |
| See full request/response detail | `noober_get_request_detail` | fast |
| Read app logs | `noober_get_app_logs` | fast |
| Check/switch API environment | `noober_get_environment` / `noober_switch_environment` | instant |
| Browse UserDefaults | `noober_get_user_defaults` | fast |
| See WebSocket frames | `noober_get_websocket_logs` | fast |
| Get recorded user flows | `noober_get_recorded_flows` | fast |

## Tool Priority for QA Testing

When verifying something, use the fastest tool:
1. `noober_check_event("event_name")` — Did this analytics event fire? PASS/FAIL.
2. `noober_get_value("Total Payable")` — What value is shown? Returns the text.
3. `noober_assert_request(url_pattern: "/api/booking", method: "POST")` — Was this API called? PASS/FAIL.
4. `noober_screen_text` — All text on screen.
5. `noober_get_app_logs` — Only when you need raw log data.
6. `noober_get_network_logs` — Only when checking full API traffic.

**NEVER use `snapshot_ui`** — it takes 20-30 seconds. Use `noober_screen_html` instead (~100ms).

## Advanced Setup (Optional)

```swift
// Register API environments for quick switching
Noober.shared.registerEnvironments([
    .init(name: "Production", baseURL: "https://api.example.com"),
    .init(name: "Staging", baseURL: "https://staging.example.com")
])

// Register QA checklist items
Noober.shared.registerChecklist([
    .init("Login flow redesign", notes: "New OTP screen", priority: .high),
    .init("Cart calculation fix", endpoints: ["/api/cart"])
])

// Register developer actions
Noober.shared.registerActions([
    .init("Clear Cache", icon: "trash") { CacheManager.clearAll() },
    .init("Reset Onboarding", icon: "arrow.counterclockwise") {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    }
])

// For custom URLSession configurations
Noober.shared.inject(into: myCustomSessionConfig)
```

## Recording Flows

Noober can record user flows for automated replay:
1. Tap the Noober debug bubble in the app
2. Tap "Record" and give the flow a name
3. Perform the user journey (tap through screens)
4. Stop recording

Recorded flows are available via `noober_get_recorded_flows` and can be replayed by NoobQA for faster test execution.

## Project Structure

- `Sources/Noober/` — Main SDK (SwiftUI views, network interceptor, log capture)
- `Sources/Noober/Companion/` — TCP server for MCP communication
- `Sources/Noober/FlowRecorder/` — User flow recording
- `Sources/Noober/Network/` — HTTP request interception
- `Sources/Noober/Logs/` — Structured logging
- `Sources/NooberShared/` — Shared models between SDK and MCP
