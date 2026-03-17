# Storage Inspector

Browse and edit UserDefaults and Keychain entries.

## Overview

The Storage tab in the debug panel provides access to your app's persistent storage without needing a separate tool.

### UserDefaults

- **Browse** all keys and their current values, sorted alphabetically
- **Type-aware editing** — Noober detects the value type (String, Int, Double, Bool, Date, Array, Dictionary) and parses your input accordingly
- **Delete** individual entries
- **Duplicate** entries with a `_copy` suffix
- **Export** all entries as formatted JSON
- **Share** the JSON export via the system share sheet
- **Toggle system keys** — show or hide Apple/NS-prefixed keys

### Keychain

- **Browse** generic password and internet password items
- **Lazy value loading** — values are fetched only when you tap an entry (for security)
- **Add** new keychain items with account, value, and service
- **Edit** existing items
- **Delete** individual entries

### App Info

View bundle version, build number, and storage details for the current app.
