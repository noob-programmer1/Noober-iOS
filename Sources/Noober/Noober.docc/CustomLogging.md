# Custom Logging

Add structured, searchable log entries to the debug panel.

## Overview

Noober's logging API lets you surface important events alongside network traffic in the debug panel.

### Adding Logs

```swift
Noober.shared.log("User signed in", level: .info, category: .init("auth"))
Noober.shared.log("Cache miss", level: .debug, category: .init("cache"))
Noober.shared.log("Payment failed", level: .error, category: .init("payments"))
```

The `log()` method is `nonisolated` and safe to call from any thread.

### Log Levels

| Level | Description |
|-------|-------------|
| `.debug` | Verbose debugging information |
| `.info` | General informational messages |
| `.warning` | Potential issues that deserve attention |
| `.error` | Errors and failures |

### Log Categories

Create custom categories to organize logs:

```swift
let auth = LogCategory("auth")
let analytics = LogCategory("analytics")
```

The built-in category is `.general` (used when no category is specified).

### Source Location

Each log automatically captures the source file and line number via `#file` and `#line` default parameters. This information is shown in the log detail view.

### Limits

Maximum 500 log entries are stored. The oldest entries are removed when the limit is reached.
