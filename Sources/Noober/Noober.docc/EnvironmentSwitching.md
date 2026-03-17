# Environment Switching

Switch between server environments with one tap.

## Overview

Register named environments with base URLs. Noober rewrites matching network requests to the active environment's base URL automatically.

### Registering Environments

```swift
Noober.shared.registerEnvironments([
    .init(name: "Production", baseURL: "https://api.example.com"),
    .init(name: "Staging",
          baseURL: "https://api.staging.example.com",
          notes: "Uses test payment keys"),
    .init(name: "Local",
          baseURL: "http://localhost:8080"),
])
```

The first environment is the default (no URL rewriting). Selecting any other environment rewrites the scheme, host, and port of matching requests while preserving the path, query, and fragment.

### Multi-URL Environments

If your app talks to multiple servers, use positional base URL mapping:

```swift
Noober.shared.registerEnvironments([
    .init(name: "Production",
          baseURLs: ["https://api.example.com", "https://cdn.example.com"]),
    .init(name: "Staging",
          baseURLs: ["https://api.staging.example.com", "https://cdn.staging.example.com"]),
])
```

Requests matching `baseURLs[0]` of the default environment are rewritten to `baseURLs[0]` of the active environment, and so on.

### Persistence

The active environment selection is saved to UserDefaults and restored on the next launch.
