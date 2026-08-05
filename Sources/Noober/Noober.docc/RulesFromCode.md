# Rules From Code

Ship mock and intercept rules with the build instead of rebuilding them by hand.

## Overview

Rules you create in the debug panel live on the device. That is fine for a one-off, but a mock the whole team needs — an empty cart, a declined payment, a 500 from search — is worth keeping in the source, where it is reviewed, versioned, and present on every install.

Register them at startup, next to your other Noober setup:

```swift
#if DEBUG
Noober.shared.registerMocks([
    .init("Empty cart", url: "/api/v1/cart", json: #"{"items": []}"#),
    .init("Payment failure", url: "/api/v1/payments", method: "POST",
          statusCode: 500, json: #"{"error": "gateway_timeout"}"#),
])

Noober.shared.start()
#endif
```

### Registering Is Idempotent

``Noober/Noober/registerMocks(_:)`` replaces everything registered from code previously — the array you pass is the complete set. Calling it on every launch is the intended usage and never accumulates duplicates.

Code-registered rules are deliberately **not** persisted. The app re-creates them each launch, so the source file is the only place they are defined: delete a mock from the array and it is gone on the next run, with no stale copy left on the device.

### Starting Switched Off

A mock that is active from launch changes what the app does for everyone who installs the build. For anything but a permanent stub, register it disabled and let whoever needs it flip the switch:

```swift
Noober.shared.registerMocks([
    .init("Payment failure", url: "/api/v1/payments", method: "POST",
          statusCode: 500, json: #"{"error": "gateway_timeout"}"#,
          isEnabled: false),
])
```

The mock sits in the Rules tab, off, one tap away — and an AI agent driving the app over NooberMCP can toggle it too. This matters more for intercepts, which pause matching requests: a rule that stops every payment call from launch will stall the app.

### Hand-Made Rules Win

Rules created in the debug panel sort above code-registered ones, and the first match serves. A tester who mocks `/api/v1/cart` by hand overrides the one shipped in the build without having to find and disable it first.

Code-registered rules carry a `CODE` badge in the Rules tabs, so it is clear which rules came from the source and will return after a relaunch.

### Adding One Rule Mid-Session

``Noober/Noober/addMock(_:)`` adds a single rule on top of every existing one, without touching the registered set. Use it from a custom action or a test hook when you want a mock to take effect right now:

```swift
Noober.shared.registerActions([
    .init("Force logged out", icon: "person.slash") {
        Noober.shared.addMock(.init("401 /me", url: "/api/v1/me", statusCode: 401))
    },
])
```

It returns the rule's id for ``Noober/Noober/removeMock(id:)``. Both `addMock` and `removeMock` work on rules created in the debug panel as well.

## Topics

### Rule Types

- ``NooberMock``
- ``NooberIntercept``
- ``NooberURLMatch``
