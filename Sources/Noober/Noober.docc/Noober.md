# ``Noober``

A powerful, zero-dependency debugging toolkit for iOS apps.

## Overview

Noober provides a complete suite of debugging tools that integrate into your iOS app via a floating overlay bubble. Tap the bubble to open a full-featured debug panel with five tabs: Network, Storage, Logs, Rules, and QA.

All `URLSession` network traffic is captured automatically — no manual instrumentation required. WebSocket connections are also monitored. The rules engine lets you rewrite URLs, mock responses, and intercept requests mid-flight for editing. Environment switching lets your team toggle between servers with one tap.

### Quick Start

```swift
#if DEBUG
import Noober

Noober.shared.start()
#endif
```

That's it. A floating bubble appears on screen. Tap it to open the debug panel.

> Warning: Noober is designed for debugging only. Always wrap usage with `#if DEBUG` to exclude it from release builds.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:NetworkInspector>
- <doc:RulesEngine>
- <doc:EnvironmentSwitching>
- <doc:CustomLogging>
- <doc:StorageInspector>
- <doc:QAChecklist>

### Public Types

- ``Noober/Noober``
- ``NooberEnvironment``
- ``QAChecklistItem``
- ``QAChecklistPriority``
- ``LogLevel``
- ``LogCategory``
