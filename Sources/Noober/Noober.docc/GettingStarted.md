# Getting Started

Set up Noober in your iOS project with one line of code.

## Overview

Noober requires iOS 13+ and Swift 6.0+. It has zero third-party dependencies.

### Installation

Add Noober via Swift Package Manager in Xcode:

1. Go to **File > Add Package Dependencies**
2. Enter: `https://github.com/noob-programmer1/Noober-iOS.git`
3. Select **Up to Next Major** from `1.0.0`

Or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/noob-programmer1/Noober-iOS.git", from: "1.0.0")
]
```

### Start Noober

```swift
#if DEBUG
import Noober

Noober.shared.start()
#endif
```

A floating bubble appears on screen. Tap it to open the debug panel. All `URLSession` network requests are captured automatically.

### Register Environments

```swift
Noober.shared.registerEnvironments([
    .init(name: "Production", baseURL: "https://api.example.com"),
    .init(name: "Staging", baseURL: "https://api.staging.example.com"),
])
```

### Register a QA Checklist

```swift
Noober.shared.registerChecklist([
    .init("Login flow", priority: .high, endpoints: ["/auth/login"]),
    .init("Checkout", notes: "Test with saved cards", priority: .high),
])
```

### Register Mocks and Intercepts

```swift
Noober.shared.registerMocks([
    .init("Empty cart", url: "/api/v1/cart", json: #"{"items": []}"#),
])

Noober.shared.registerIntercepts([
    .init("Payments", url: "/api/v1/payments", method: "POST", isEnabled: false),
])
```

Registering replaces the previously registered set, so this is safe to call on every launch. See <doc:RulesFromCode>.

### Register Debugger Actions

```swift
Noober.shared.registerActions([
    .init("Clear Cache", icon: "trash") { CacheManager.shared.clearAll() },
])
```

### Add Custom Logs

```swift
Noober.shared.log("User signed in", level: .info, category: .init("auth"))
```

### Stop Noober

```swift
Noober.shared.stop()
```

This removes the bubble, clears all captured data, and uninstalls all interceptors.
