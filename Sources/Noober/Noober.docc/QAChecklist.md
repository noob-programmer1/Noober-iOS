# QA Checklist

Track QA testing progress with a build-aware checklist.

## Overview

Register checklist items for each build. Noober tracks pass/fail status per build number and auto-resets when a new build is detected.

### Registering Items

```swift
Noober.shared.registerChecklist([
    .init("Login flow",
          notes: "Test with email + social login",
          priority: .high,
          endpoints: ["/auth/login", "/auth/social"]),
    .init("Checkout",
          notes: "Test with & without saved cards",
          priority: .high,
          endpoints: ["/api/payments"]),
    .init("Pull-to-refresh on feed",
          priority: .normal),
    .init("Dark mode rendering",
          priority: .low),
])
```

### Parameters

- **title** — what to test
- **notes** — additional context or instructions
- **priority** — `.high`, `.normal`, or `.low` (affects sort order)
- **endpoints** — associated API endpoints (helps connect failures to network requests)

### Tracking Results

In the QA tab of the debug panel:
- **Pass** — mark an item as tested and working
- **Fail** — mark as failed with notes and optionally attach captured network requests
- **Reset** — return an item to pending status

### Build Awareness

Checklist state is keyed by the app's build number (`CFBundleVersion`). When Noober detects a new build number, it resets all statuses to pending while preserving the item definitions from `registerChecklist(_:)`.
